/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Core Audio Utilities
*/
#include "CADebugMacros.h"
#include <stdio.h>
#include <stdarg.h>
#if TARGET_API_MAC_OSX
	#include <syslog.h>
#endif

#if DEBUG
#include <stdio.h>

void	DebugPrint(const char *fmt, ...)
{
	va_list args;
	va_start(args, fmt);
	vprintf(fmt, args);
	va_end(args);
}
#endif // DEBUG

void	LogError(const char *fmt, ...)
{
	va_list args;
	va_start(args, fmt);
#if DEBUG
	vprintf(fmt, args);
#endif
#if TARGET_API_MAC_OSX
	vsyslog(LOG_ERR, fmt, args);
#endif
	va_end(args);
}

void	LogWarning(const char *fmt, ...)
{
	va_list args;
	va_start(args, fmt);
#if DEBUG
	vprintf(fmt, args);
#endif
#if TARGET_API_MAC_OSX
	vsyslog(LOG_WARNING, fmt, args);
#endif
	va_end(args);
}
