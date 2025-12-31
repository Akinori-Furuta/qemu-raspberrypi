// SPDX-License-Identifier: GPL-2.0+
/*
 * Simple power off and restart driver for Broadcom BCM2835
 * emulated by QEMU Based on following sources,
 *  drivers/mfd/bcm2835-pm.c
 *  drivers/watchdog/bcm2835_wdt.c
 *  drivers/firmware/raspberrypi.c
 *  drivers/usb/host/dwc_otg/dwc_otg_regs.h
 *  drivers/usb/host/dwc_otg/dwc_otg_cil.c
 *  drivers/usb/host/dwc_common_port/dwc_common_linux.c
 * One up these drivers into simple power off and restart driver.
 *
 * This driver binds to the PM block and setup pm_power_off and
 * restart_handler function.
 */

#include <linux/types.h>
#include <linux/spinlock.h>
#include <linux/atomic.h>
#include <linux/module.h>
#include <linux/notifier.h>
#include <linux/delay.h>
#include <linux/regmap.h>
#include <linux/ioport.h>
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
	void __iomem	*dwc_base;
	pm_power_off_func_t	*saved_pm_power_off;
	bool		removed_power_off;
	bool		removed_restart;
};

#define	WDOG_TICKS_PER_1SEC	(65536)
#define	WDOG_TICKS_MAX		(PM_WDOG_TIME_SET)
#define	WDOG_PERIOD_US_MAX	(((u64)WDOG_TICKS_MAX * 1000000) / WDOG_TICKS_PER_1SEC)
#define	WDOG_RECIPROCAL_SHIFT	(16)

#define	FIXED_POINT_MULDIV_U64(a, m, d, s) \
	((((u64)(a) * (((u64)(m) << (s)) / (d))) \
		+ ((u64)1 << ((s) - 1))) >> (s))

#define WDOG_USECS_TO_TICKS(us)	\
	FIXED_POINT_MULDIV_U64(us, WDOG_TICKS_PER_1SEC, 1000000, \
		WDOG_RECIPROCAL_SHIFT)

/* Static context used by bcm2835_pm_poff_handler() */
static struct bcm2835_pm_poff bcm2835_pm_poff_single;

static int bcm2835_pm_poff_bark_us_set(const char *val, const struct kernel_param *kp)
{	int	ret;
	uint	*us_ptr;
	uint	us;
	uint	us_saved;
	u32	tick;

	us_ptr = (__force uint *)(kp->arg);
	if (!us_ptr) {
		/* NULL points parameter variable. */
		return -ENODEV;
	}

	us_saved = *us_ptr;
	ret = kstrtouint(val, 0, (uint *)(kp->arg));
	if (ret) {
		/* parse error. */
		return ret;
	}

	us = *us_ptr;
	if (us > WDOG_PERIOD_US_MAX) {
		/* Too large period. */
		pr_err("%s: Store too large value to bark_us. max=%lu\n",
			__func__,
			(unsigned long)WDOG_PERIOD_US_MAX
		);
		*us_ptr = us_saved;
		return -ERANGE;
	}

	tick = WDOG_USECS_TO_TICKS(us);
	pr_info("%s: Update bark reboot time. bark_us=%u, tick=%u\n",
		__func__,
		us,
		tick
	);
	return ret;
}

#define	WDOG_BARK_US_DEF	(15)
static uint bark_us = WDOG_BARK_US_DEF;
static struct kernel_param_ops bark_us_ops = {
	.set = bcm2835_pm_poff_bark_us_set,
	.get = param_get_uint,
};
module_param_cb(bark_us, &bark_us_ops, &bark_us, 0644);
MODULE_PARM_DESC(bark_us, "Write watchdog register then bark reboot time in micro seconds");

#define	REBOOT_HOLD_OFF_MS_DEF	(1)
static uint hold_off_ms = REBOOT_HOLD_OFF_MS_DEF;
module_param(hold_off_ms, uint, 0644);
MODULE_PARM_DESC(hold_off_ms, "mdelay time after initiated reboot in milli seconds");

/* Common hardware access part. */

static DEFINE_SPINLOCK(bcm2835_pm_poff_wdog_lock);

/*
 * The Raspberry Pi firmware uses the RSTS register to know which partiton
 * to boot from. The partiton value is spread into bits 0, 2, 4, 6, 8, 10.
 * @pre spin lock bcm2835_pm_poff_wdog_lock
 */

static void __bcm2835_pm_poff_restart(struct bcm2835_pm_poff *pm, u8 partition)
{
	u32 val, rsts;
	void __iomem *base = pm->base;
	u32 ticks;

	/* Calculate ticks to expire watchdog. */
	ticks = WDOG_USECS_TO_TICKS(bark_us);

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

	writel_relaxed(ticks | PM_PASSWORD, base + PM_WDOG);
	val = readl_relaxed(base + PM_RSTC);
	val &= PM_RSTC_WRCFG_CLR;
	val |= PM_PASSWORD | PM_RSTC_WRCFG_FULL_RESET;
	writel_relaxed(val, base + PM_RSTC);

	/* No sleeping, here is atomic context. */
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
	unsigned long flags;

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

	spin_lock_irqsave(&bcm2835_pm_poff_wdog_lock, flags);
	__bcm2835_pm_poff_restart(pm, PM_BOOT_PART_FROM_HALT);
	spin_unlock_irqrestore(&bcm2835_pm_poff_wdog_lock, flags);
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

/* DWC OTG controller section. */

/** DWC_otg Core registers .
 * The dwc_otg_core_global_regs structure defines the size
 * and relative field offsets for the Core Global registers.
 */
struct /* aliased */ dwc_otg_core_global_regs {
	/** OTG Control and Status Register.  <i>Offset: 000h</i> */
	volatile uint32_t gotgctl;
	/** OTG Interrupt Register.	 <i>Offset: 004h</i> */
	volatile uint32_t gotgint;
	/**Core AHB Configuration Register.	 <i>Offset: 008h</i> */
	volatile uint32_t gahbcfg;

#define DWC_GLBINTRMASK		0x0001
#define DWC_DMAENABLE		0x0020
#define DWC_NPTXEMPTYLVL_EMPTY	0x0080
#define DWC_NPTXEMPTYLVL_HALFEMPTY	0x0000
#define DWC_PTXEMPTYLVL_EMPTY	0x0100
#define DWC_PTXEMPTYLVL_HALFEMPTY	0x0000

	/**Core USB Configuration Register.	 <i>Offset: 00Ch</i> */
	volatile uint32_t gusbcfg;
	/**Core Reset Register.	 <i>Offset: 010h</i> */
	volatile uint32_t grstctl;
	/**Core Interrupt Register.	 <i>Offset: 014h</i> */
	volatile uint32_t gintsts;
	/**Core Interrupt Mask Register.  <i>Offset: 018h</i> */
	volatile uint32_t gintmsk;
	/**Receive Status Queue Read Register (Read Only).	<i>Offset: 01Ch</i> */
	volatile uint32_t grxstsr;
	/**Receive Status Queue Read & POP Register (Read Only).  <i>Offset: 020h</i>*/
	volatile uint32_t grxstsp;
	/**Receive FIFO Size Register.	<i>Offset: 024h</i> */
	volatile uint32_t grxfsiz;
	/**Non Periodic Transmit FIFO Size Register.  <i>Offset: 028h</i> */
	volatile uint32_t gnptxfsiz;
	/**Non Periodic Transmit FIFO/Queue Status Register (Read
	 * Only). <i>Offset: 02Ch</i> */
	volatile uint32_t gnptxsts;
	/**I2C Access Register.	 <i>Offset: 030h</i> */
	volatile uint32_t gi2cctl;
	/**PHY Vendor Control Register.	 <i>Offset: 034h</i> */
	volatile uint32_t gpvndctl;
	/**General Purpose Input/Output Register.  <i>Offset: 038h</i> */
	volatile uint32_t ggpio;
	/**User ID Register.  <i>Offset: 03Ch</i> */
	volatile uint32_t guid;
	/**Synopsys ID Register (Read Only).  <i>Offset: 040h</i> */
	volatile uint32_t gsnpsid;
	/**User HW Config1 Register (Read Only).  <i>Offset: 044h</i> */
	volatile uint32_t ghwcfg1;
	/**User HW Config2 Register (Read Only).  <i>Offset: 048h</i> */
	volatile uint32_t ghwcfg2;
#define DWC_SLAVE_ONLY_ARCH 0
#define DWC_EXT_DMA_ARCH 1
#define DWC_INT_DMA_ARCH 2

#define DWC_MODE_HNP_SRP_CAPABLE	0
#define DWC_MODE_SRP_ONLY_CAPABLE	1
#define DWC_MODE_NO_HNP_SRP_CAPABLE		2
#define DWC_MODE_SRP_CAPABLE_DEVICE		3
#define DWC_MODE_NO_SRP_CAPABLE_DEVICE	4
#define DWC_MODE_SRP_CAPABLE_HOST	5
#define DWC_MODE_NO_SRP_CAPABLE_HOST	6

	/**User HW Config3 Register (Read Only).  <i>Offset: 04Ch</i> */
	volatile uint32_t ghwcfg3;
	/**User HW Config4 Register (Read Only).  <i>Offset: 050h</i>*/
	volatile uint32_t ghwcfg4;
	/** Core LPM Configuration register <i>Offset: 054h</i>*/
	volatile uint32_t glpmcfg;
	/** Global PowerDn Register <i>Offset: 058h</i> */
	volatile uint32_t gpwrdn;
	/** Global DFIFO SW Config Register  <i>Offset: 05Ch</i> */
	volatile uint32_t gdfifocfg;
	/** ADP Control Register  <i>Offset: 060h</i> */
	volatile uint32_t adpctl;
	/** Reserved  <i>Offset: 064h-0FFh</i> */
	volatile uint32_t reserved39[39];
	/** Host Periodic Transmit FIFO Size Register. <i>Offset: 100h</i> */
	volatile uint32_t hptxfsiz;
	/** Device Periodic Transmit FIFO#n Register if dedicated fifos are disabled,
		otherwise Device Transmit FIFO#n Register.
	 * <i>Offset: 104h + (FIFO_Number-1)*04h, 1 <= FIFO Number <= 15 (1<=n<=15).</i> */
	volatile uint32_t dtxfsiz[15];
};

/**
 * This union represents the bit fields of the Core AHB Configuration
 * Register (GAHBCFG). Set/clear the bits using the bit fields then
 * write the <i>d32</i> value to the register.
 */
union /* aliased */ gahbcfg_data {
	/** raw register data */
	uint32_t d32;
	/** register bits */
	struct {
		unsigned glblintrmsk:1;
#define DWC_GAHBCFG_GLBINT_ENABLE		1

		unsigned hburstlen:4;
#define DWC_GAHBCFG_INT_DMA_BURST_SINGLE	0
#define DWC_GAHBCFG_INT_DMA_BURST_INCR		1
#define DWC_GAHBCFG_INT_DMA_BURST_INCR4		3
#define DWC_GAHBCFG_INT_DMA_BURST_INCR8		5
#define DWC_GAHBCFG_INT_DMA_BURST_INCR16	7

		unsigned dmaenable:1;
#define DWC_GAHBCFG_DMAENABLE			1
		unsigned reserved:1;
		unsigned nptxfemplvl_txfemplvl:1;
		unsigned ptxfemplvl:1;
#define DWC_GAHBCFG_TXFEMPTYLVL_EMPTY		1
#define DWC_GAHBCFG_TXFEMPTYLVL_HALFEMPTY	0
		unsigned reserved9_20:12;
		unsigned remmemsupp:1;
		unsigned notialldmawrit:1;
		unsigned ahbsingle:1;
		unsigned reserved24_31:8;
	} b;
};

/**
 * This function disables the controller's Global Interrupt in the AHB Config
 * register.
 *
 * @param core_if Programming view of DWC_otg controller.
 */
static void dwc_otg_restart_disable_global_interrupts(
	struct bcm2835_pm_poff *pm)
{
	struct /* aliased */ dwc_otg_core_global_regs *core_regs;
	u32 reg;
	union /* aliased */ gahbcfg_data ahbcfg = {.d32 = 0 };

	core_regs = pm->dwc_base;
	if (!core_regs) {
		/* We don't know DWC OTG controller address. */
		return;
	}

	ahbcfg.b.glblintrmsk = 1;	/* Disable interrupts */

	dev_info(pm->dev, "Disable DWC USB-OTG interrupt.\n");
	reg = readl(&(core_regs->gahbcfg));
	reg &= ~ahbcfg.d32;
	writel(reg, &(core_regs->gahbcfg));
	wmb();
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
	unsigned long flags;

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

	/* note: All other CPUs may be halted. see kernel_restart() and
	 *       migrate_to_reboot_cpu().
	 * Disable interrupt(s) for a while, some drivers left IRQ line
	 * active. We noticed DWC (USB OTG) controller driver may hang at
	 * rebooting due to handle IRQ without device context.
	 */
	spin_lock_irqsave(&bcm2835_pm_poff_wdog_lock, flags);
	__bcm2835_pm_poff_restart(pm, partition);
	/* may be reboot process started before come here. */
	spin_unlock_irqrestore(&bcm2835_pm_poff_wdog_lock, flags);

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

/* Resource "pm", watchdog/boot from selected partition. */
#define	BCM2835_PM_POFF_DT_REGS_PM		(0)
/* Resource "asb", not used. */
#define	BCM2835_PM_POFF_DT_REGS_ASB		(1)
/* Resource "usb0base", DWC OTG controller. */
#define	BCM2835_PM_POFF_DT_REGS_USB0BASE	(2)

static int bcm2835_pm_poff_get_pdata(struct platform_device *pdev,
				struct bcm2835_pm_poff *pm)
{
	struct device *dev = &(pdev->dev);
	struct resource *res;
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

		/* note: To bypass checking a memory region already in use,
		 *       Use platform_get_resource_byname(),
		 *       and devm_ioremap() directly.
		 */
		res = platform_get_resource_byname(pdev, IORESOURCE_MEM, "usb0base");
		if (!res) {
			/* No resource (physical {address, size})
			 * referring to DWC USB-OTG.
			 */
			dev_notice(dev, "Skip masking DWC USB-OTG interrupt at rebooting.\n"
			);
		} else {
			/* We will mask DWG USB-OTG controller interrupt at rebooting. */
			base = devm_ioremap(&(pdev->dev),
				res->start, resource_size(res)
			);
			if (!base) {
				/* Can't get virtual address to
				 * access DWC USB-OTC controller.
				 */
				dev_notice(dev, "Skip masking DWC USB-OTG interrupt at rebooting, can not map aliased virtual address.\n"
				);
			} else {
				/* We get aliased virtual address to
				 * access DWC USB-OTG controller.
				 */
				pm->dwc_base = base;
			}
		}

		return 0;
	}

	/* If no 'reg-names' property is found we can assume
	 * we're using old DTB, read reg property by index.
	 */
	base = devm_platform_ioremap_resource(pdev,
		BCM2835_PM_POFF_DT_REGS_PM
	);
	if (IS_ERR(base)) {
		int	err;

		err = PTR_ERR(base);
		dev_err(dev, "No IOMEM resource index %d. err=%d\n",
			BCM2835_PM_POFF_DT_REGS_PM,
			err
		);
		return err;
	}
	pm->base = base;

	res = platform_get_resource(pdev, IORESOURCE_MEM,
		BCM2835_PM_POFF_DT_REGS_USB0BASE
	);
	if (!res) {
		dev_notice(dev, "No mem resource, skip masking DWC USB-OTG interrupt at rebooting. index=%d\n",
			BCM2835_PM_POFF_DT_REGS_USB0BASE
		);
	} else {
		base = devm_ioremap(&(pdev->dev),
			res->start, resource_size(res)
		);
		if (!base) {
			/* Can't get virtual address to
			 * access DWC USB-OTC controller.
			 */
			dev_notice(dev, "Skip masking DWC USB-OTG interrupt at rebooting, can not map mem resource. index=%d.\n",
				BCM2835_PM_POFF_DT_REGS_USB0BASE
			);
		} else {
			/* We get aliased virtual address to
			 * access DWC USB-OTG controller.
			 */
			pm->dwc_base = base;
		}
	}

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

	dev_info(dev, "Module parameter. bark_us=%u, bark_ticks=%u, hold_off_ms=%u\n",
		bark_us,
		(unsigned)WDOG_USECS_TO_TICKS(bark_us),
		hold_off_ms
	);

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

static void bcm2835_pm_poff_shutdown(struct platform_device *pdev)
{
	struct bcm2835_pm_poff *pm = platform_get_drvdata(pdev);

	/* Shutdown DWC USB-OTG controller. */
	dwc_otg_restart_disable_global_interrupts(pm);
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
	.shutdown	= bcm2835_pm_poff_shutdown,
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
