// SPDX-License-Identifier: GPL-2.0+
/*
 * Simple power off and restart driver for Broadcom BCM2835
 * emulated by QEMU Based on drivers/mfd/bcm2835-pm.c,
 * drivers/watchdog/bcm2835_wdt.c, and drivers/firmware/raspberrypi.c
 * One up these drivers into simple power off and restart driver.
 *
 * This driver binds to the PM block and setup pm_power_off and
 * restart_handler function.
 */

#include <linux/types.h>
#include <linux/atomic.h>
#include <linux/module.h>
#include <linux/notifier.h>
#include <linux/delay.h>
#include <linux/regmap.h>
#include <linux/io.h>
#include <linux/of_address.h>
#include <linux/of_platform.h>
#include <linux/platform_device.h>
#include <linux/pm.h>
#include <linux/reboot.h>
#include <linux/version.h>

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
#define PM_BOOT_PART_AUTO_SCAN		(0)
#define	PM_BOOT_PART_FROM_HALT		(63)
#define	PM_BOOT_PART_MAX		(63)

typedef void (pm_power_off_func_t)(void);

struct bcm2835_pm_poff {
	struct device	*dev;
	void __iomem	*base;
	pm_power_off_func_t	*saved_pm_power_off;
	bool		removed_power_off;
	bool		removed_restart;
};

/* Static context used by bcm2835_pm_poff_handler() */
static struct bcm2835_pm_poff bcm2835_pm_poff_single;

#define	REBOOT_HOLD_OFF_MS_DEF	(10)
static uint hold_off_ms = REBOOT_HOLD_OFF_MS_DEF;
module_param(hold_off_ms, uint, 0644);
MODULE_PARM_DESC(hold_off_ms, "mdelay time after initiated reboot in milli seconds");

/* Common hardware access part. */

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
	mdelay(hold_off_ms);
}

/* Power off part */

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

	if (pm->removed_power_off) {
		/* Some one remember us after removed module,
		 * and call us.
		 */
		pr_warn("%s: Called after removed.\n", __func__);
	}

	__bcm2835_pm_poff_restart(pm, PM_BOOT_PART_FROM_HALT);
}

static void bcm2835_pm_poff_handoff_power_off(struct bcm2835_pm_poff *pm)
{
	struct device *dev = pm->dev;
	pm_power_off_func_t *cur_pm_power_off;

	cur_pm_power_off = cmpxchg(&pm_power_off,
		bcm2835_pm_poff_handler,	/* old */
		pm->saved_pm_power_off		/* new (restore value). */
	);

	if (cur_pm_power_off != bcm2835_pm_poff_handler) {
		/* Another driver handles power off driver. */
		dev_warn(dev, "Another driver handles pm_power_off().\n");
	}
	dev_info(dev, "Removed power off handler.\n");
}


static int bcm2835_pm_poff_overtake_power_off(struct bcm2835_pm_poff *pm)
{
	struct device *dev;
	pm_power_off_func_t *priv_pm_power_off;

	dev = pm->dev;

	priv_pm_power_off = xchg(&pm_power_off, bcm2835_pm_poff_handler);
	pm->saved_pm_power_off = priv_pm_power_off;
	if (priv_pm_power_off) {
		/* Someone already handles power off. */
		dev_notice(dev, "Someone already handles power off, we override it.\n");
	}

	return 0;
}

/* Reboot part. */

/*
 * Reboot callback.
 * note: Ignore enum reboot_mode mode
 */
static int bcm2835_pm_poff_restart_handler(struct notifier_block *nb,
				      unsigned long mode,
				      void *data)
{
	struct bcm2835_pm_poff *pm = &bcm2835_pm_poff_single;
	unsigned long val = PM_BOOT_PART_AUTO_SCAN;
	u8 partition = PM_BOOT_PART_AUTO_SCAN;

	if (pm->dev == NULL) {
		pr_warn("%s: Invalid device context. mode=0x%lx\n",
			__func__,
			mode
		);
		/* We can't handle, but we hope continue. */
		return 0;
	}

	if (pm->removed_restart) {
		pr_warn("%s: Called after removed. mode=0x%lx\n",
			__func__,
			mode
		);

		return 0;
	}

	if (data) {
		int items;

		items = sscanf(data, "%lu", &val);

		if (items == 0) {
			/* It's not a unsigned long value. */
			val = PM_BOOT_PART_AUTO_SCAN;
		}

		if (val > PM_BOOT_PART_MAX) {
			/* Invalid partition number. */
			val = PM_BOOT_PART_AUTO_SCAN;
		}
		partition = (__force u8)val;
	}

	__bcm2835_pm_poff_restart(pm, partition);
	/* may be reboot process started before come here. */
	return NOTIFY_DONE;
}

static struct notifier_block bcm2835_pm_poff_restart_nb = {
	.notifier_call = bcm2835_pm_poff_restart_handler,
};

/* Probe/Rmove part */

static int bcm2835_pm_poff_save_context(struct bcm2835_pm_poff *pm)
{
	struct device *dev;

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

	return 0;
}

static int bcm2835_pm_poff_get_pdata(struct platform_device *pdev,
				struct bcm2835_pm_poff *pm)
{
	struct device *dev = &(pdev->dev);
	void __iomem *base;

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,1,75)
	/* See commit 79de65ac39d75ef68062d6a1fd0d719015af0898 */
	if (of_property_present(dev->of_node, "reg-names")) {
#else /* LINUX_VERSION_CODE >= KERNEL_VERSION(6,1,75) */
	/* note: reg-names is string list property,
	 * To check if there is reg-names property,
	 * read it as bool.
	 */
	if (of_property_read_bool(dev->of_node, "reg-names")) {
#endif /* LINUX_VERSION_CODE >= KERNEL_VERSION(6,1,75) */
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

	ret = bcm2835_pm_poff_save_context(pm);
	if (ret) {
		/* We have already prepared static singleton context. */
		return ret;
	}

	if (of_device_is_system_power_controller(np)) {
		/* We have system power control. */
		ret = bcm2835_pm_poff_overtake_power_off(pm);
		if (ret) {
			/* Can't handle power off. */
			return ret;
		}
		dev_info(dev, "Installed power off handler.\n");

		ret = register_restart_handler(&bcm2835_pm_poff_restart_nb);
		if (ret != 0) {
			/* Can not register restart handler. */
			dev_err(dev, "Can not register restart handler. ret=%d\n",
				ret
			);
			goto out_recover_poff_handler;
		}
		dev_info(dev, "Registered restart handler.\n");
	} else {
		/* Match to device tree compatible,
		 * but without system-power-controller.
		 */
		dev_notice(dev, "This module does NOTHING, put device tree property system-power-controller.\n"
		);
	}
	return 0;

out_recover_poff_handler:
	bcm2835_pm_poff_single.removed_power_off = true;
	wmb();
	bcm2835_pm_poff_handoff_power_off(pm);
	bcm2835_pm_poff_single.removed_restart = true;
	wmb();

	return ret;
}

#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,11,0)
/* See commit 0edb555a65d1ef047a9805051c36922b52a38a9d */
static void bcm2835_pm_poff_remove(struct platform_device *pdev)
#else /* LINUX_VERSION_CODE >= KERNEL_VERSION(6,11,0) */
static int bcm2835_pm_poff_remove(struct platform_device *pdev)
#endif /* LINUX_VERSION_CODE >= KERNEL_VERSION(6,11,0) */
{
	struct bcm2835_pm_poff *pm = platform_get_drvdata(pdev);
	struct device *dev;
	int ret;

	dev = pm->dev;

	bcm2835_pm_poff_single.removed_power_off = true;
	wmb();
	bcm2835_pm_poff_handoff_power_off(pm);

	bcm2835_pm_poff_single.removed_restart = true;
	wmb();
	/* note: If we call unregister_restart_handler() with notifier block
	 *       which is not registered. we will get -ENOENT and
	 *       nothing is changed.
	 */
	ret = unregister_restart_handler(&bcm2835_pm_poff_restart_nb);
	if (ret) {
		/* May be notifier block chain broken. */
		dev_warn(dev, "Can not remove restart handler. ret=%d\n",
			ret
		);
	} else {
		/* Found our handler and removed it. */
		dev_info(dev, "Removed restart handler.\n");
	}
	/* note: Managed resources pm and iomap will
	 * be freed by drivers/base.
	 */
#if LINUX_VERSION_CODE >= KERNEL_VERSION(6,11,0)
	/* See commit 0edb555a65d1ef047a9805051c36922b52a38a9d */
	/* return nothing. */
#else /* LINUX_VERSION_CODE >= KERNEL_VERSION(6,11,0) */
	return 0 /* Will be ignored. */;
#endif /* LINUX_VERSION_CODE >= KERNEL_VERSION(6,11,0) */
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
