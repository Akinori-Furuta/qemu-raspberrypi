#include <stdint.h>
#include <inttypes.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#define	u32	uint32_t
#define	u64	uint64_t

#define	FIXED_POINT_MULDIV_U64(a, m, d, s) \
	((((u64)(a) * (((u64)(m) << (s)) / (d))) \
		+ ((u64)1 << ((s) - 1))) >> (s))

#define	WDOG_TICKS_PER_1SEC	(65536)
#define	WDOG_RECIPROCAL_SHIFT	(16)
#define USECS_TO_WDOG_TICKS(us)	\
	FIXED_POINT_MULDIV_U64(us, WDOG_TICKS_PER_1SEC, 1000000, \
		WDOG_RECIPROCAL_SHIFT)

/* (((u64)(us)) * \ */
/*	(((u64)WDOG_TICKS_PER_1SEC << (u64)WDOG_RECIPROCAL_SHIFT) / 1000000) + \ */
/*	(1 << (WDOG_RECIPROCAL_SHIFT - 1))) >> WDOG_RECIPROCAL_SHIFT) */

int main(int argc, char **argv)
{	unsigned int	us;
	u32		ticks;
	char		*p;

	argv++;
	while ((p = *argv) != NULL) {
		char	*p2;

		us = (unsigned int)strtoul(p, &p2, 0);
		ticks = USECS_TO_WDOG_TICKS(us);
		printf("us=%u, ticks=%u\n", us, (unsigned int)ticks);
		argv++;
	}
	return 0;
}
