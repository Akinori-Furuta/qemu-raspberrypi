// SPDX-License-Identifier: GPL-2.0+
/*
 * Simple power off driver for Broadcom BCM2835 emulated by QEMU
 * Based on bcm2835-pm.c and bcm2835_wdt.c.
 * One up bcm2835-pm.c and bcm2835_wdt.c into simple power off driver.
 * Turn Multi Function Driver(MFD) into Single function driver.
 *
 * This driver binds to the PM block and setup pm_power_off function.
 * Do not touch watchdog registers.
 */

#include <linux/types.h>
#include <linux/atomic.h>
#include <linux/module.h>
#include <linux/delay.h>
#include <linux/regmap.h>
#include <linux/io.h>
#include <linux/of_address.h>
#include <linux/of_platform.h>
#include <linux/platform_device.h>
#include <linux/pm.h>

#define PM_RSTC				0x1c
#define PM_RSTS				0x20
#define PM_WDOG				0x24

#define PM_PASSWORD			0x5a000000

#define PM_WDOG_TIME_SET		0x000fffff
#define PM_RSTC_WRCFG_CLR		0xffffffcf
#define PM_RSTS_HADWRH_SET		0x00000040	/* Not used. */
#define PM_RSTC_WRCFG_SET		0x00000030	/* Not used. */
#define PM_RSTC_WRCFG_FULL_RESET	0x00000020
#define PM_RSTC_RESET			0x00000102
#define PM_RSTS_PARTITION_CLR		0xfffffaaa

/* Boot partition number(s). */
/* Boot from partition 63 will power off.
 *  Partiton 63 is a special partition to initiate halt.
 */
#define	PM_BOOT_PART_FROM_HALT		(63)

typedef void (pm_power_off_func_t)(void);

struct bcm2835_pm_poff {
	struct device	*dev;
	void __iomem	*base;
	pm_power_off_func_t	*saved_pm_power_off;
	bool		removed;
};

/* Static context used by bcm2835_pm_poff_handler() */
static struct bcm2835_pm_poff bcm2835_pm_poff_single;

/*
 * The Raspberry Pi firmware uses the RSTS register to know which partiton
 * to boot from. The partiton value is spread into bits 0, 2, 4, 6, 8, 10.
 */

static void __bcm2835_pm_poff_restart(struct bcm2835_pm_poff *pm, u8 partition)
{
	u32 val, rsts;
	void __iomem *base = pm->base;

	/* map bits as follows,
	 * partition:    x  x  x  x  x b5 b4 b3 b2 b1 b0
	 * rsts:        b5  0 b4  0 b3  0 b2  0 b1  0 b0
	 */
	rsts = ((partition & BIT(0)) << 0) | ((partition & BIT(1)) << 1) |
	       ((partition & BIT(2)) << 2) | ((partition & BIT(3)) << 3) |
	       ((partition & BIT(4)) << 4) | ((partition & BIT(5)) << 5);

	val = readl_relaxed(base + PM_RSTS);
	val &= PM_RSTS_PARTITION_CLR;
	val |= PM_PASSWORD | rsts;
	writel_relaxed(val, base + PM_RSTS);

	/* use a timeout of 10 ticks (~150us) */
	writel_relaxed(10 | PM_PASSWORD, base + PM_WDOG);
	val = readl_relaxed(base + PM_RSTC);
	val &= PM_RSTC_WRCFG_CLR;
	val |= PM_PASSWORD | PM_RSTC_WRCFG_FULL_RESET;
	writel_relaxed(val, base + PM_RSTC);

	/* No sleeping, possibly atomic. */
	mdelay(1);
}

/*
 * We can't really power off, but if we do the normal reset scheme, and
 * indicate to bootcode.bin not to reboot, then most of the chip will be
 * powered off.
 */
static void bcm2835_pm_poff_handler(void)
{
	struct bcm2835_pm_poff *pm = &bcm2835_pm_poff_single;

	if (!(pm->base)) {
		pr_warn("%s: Called before probe.\n", __func__);
		/* We don't have virtual address to access PM_x registers.
		 * Also, we don't have device context.
		 */
		return;	/* Or shall we painc? */
	}

	if (pm->removed) {
		/* Some one remember us after removed module,
		 * and call us.
		 */
		pr_warn("%s: Called after removed.\n", __func__);
	}

	__bcm2835_pm_poff_restart(pm, PM_BOOT_PART_FROM_HALT);
}

static int bcm2835_pm_poff_handle_power_off(struct bcm2835_pm_poff *pm)
{
	struct device *dev;
	pm_power_off_func_t *priv_pm_power_off;

	dev = pm->dev;
	if (bcm2835_pm_poff_single.dev != NULL) {
		/* What happen, we already handled power off call back. */
		int ret;

		ret = -EBUSY;
		dev_warn(dev, "Handle power off call back twice or more, may be duplicated in device tree. ret=%d\n",
			ret
		);
		return ret;
	}

	/* Save context as static singleton. */
	bcm2835_pm_poff_single = *pm;

	priv_pm_power_off = xchg(&pm_power_off, bcm2835_pm_poff_handler);
	pm->saved_pm_power_off = priv_pm_power_off;
	if (priv_pm_power_off) {
		/* Someone already handles power off. */
		dev_notice(dev, "Someone already handles power off, it's overrided.\n");
	}

	return 0;
}

static int bcm2835_pm_poff_get_pdata(struct platform_device *pdev,
				struct bcm2835_pm_poff *pm)
{
	struct device *dev = &(pdev->dev);
	void __iomem *base;

	if (of_property_present(dev->of_node, "reg-names")) {
		/* There is(are) named iomem resource(s). */
		base = devm_platform_ioremap_resource_byname(pdev, "pm");
		if (IS_ERR(base)) {
			int err;

			err = PTR_ERR(base);
			dev_err(dev, "Can not find IOMEM resource pm. err=%d\n",
				err
			);
			return err;
		}
		pm->base = base;

		return 0;
	}

	/* If no 'reg-names' property is found we can assume
	 * we're using old DTB, read reg property by index.
	 */
	base = devm_platform_ioremap_resource(pdev, 0);
	if (IS_ERR(base)) {
		int	err;

		err = PTR_ERR(base);
		dev_err(dev, "No IOMEM resource index 0. err=%d\n", err);
		return err;
	}
	pm->base = base;

	return 0;
}

static const struct of_device_id bcm2835_pm_poff_of_match[] = {
	{ .compatible = "brcm,bcm2835-pm-power-off", },
	{},
};
MODULE_DEVICE_TABLE(of, bcm2835_pm_poff_of_match);

static int bcm2835_pm_poff_probe(struct platform_device *pdev)
{
	struct device *dev = &(pdev->dev);
	struct device_node *np = dev->of_node;
	struct bcm2835_pm_poff *pm;
	int ret;

	pm = devm_kzalloc(dev, sizeof(*pm), GFP_KERNEL);
	if (!pm) {
		/* Not enough memory, may alternate
		 * static bcm2835_pm_poff_single ?
		 */
		return -ENOMEM;
	}

	platform_set_drvdata(pdev, pm);

	pm->dev = dev;

	ret = bcm2835_pm_poff_get_pdata(pdev, pm);
	if (ret) {
		/* Not enough device tree property. */
		return ret;
	}

	if (of_device_is_system_power_controller(np)) {
		/* We have system power control. */
		ret = bcm2835_pm_poff_handle_power_off(pm);
		if (ret != 0) {
			/* Can't handle power off. */
			return ret;
		}
		dev_info(dev, "Installed power off handler.\n");
	}

	return 0;
}

static void bcm2835_pm_poff_remove(struct platform_device *pdev)
{
	struct bcm2835_pm_poff *pm = platform_get_drvdata(pdev);
	struct device *dev = &(pdev->dev);
	pm_power_off_func_t *cur_pm_power_off;

	cur_pm_power_off = cmpxchg(&pm_power_off,
		bcm2835_pm_poff_handler,	/* old */
		pm->saved_pm_power_off		/* new (restore value). */
	);

	if (cur_pm_power_off != bcm2835_pm_poff_handler) {
		/* Another driver handles power off driver. */
		dev_warn(dev, "Another driver handles pm_power_off().\n");
	}
	bcm2835_pm_poff_single.removed = true;
	dev_info(dev, "Removed.\n");
	/* note: Managed resource pm will be freed by drivers/base */
}

static struct platform_driver bcm2835_pm_poff_driver = {
	.probe		= bcm2835_pm_poff_probe,
	.remove		= bcm2835_pm_poff_remove,
	.driver	= {
		.name =	"bcm2835-pm-power-off",
		.of_match_table = bcm2835_pm_poff_of_match,
	},
};
module_platform_driver(bcm2835_pm_poff_driver);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Akinori Furuta <afuruta@m7.dion.ne.jp>");
MODULE_DESCRIPTION("Broadcom BCM2835 PM simple power off driver");
