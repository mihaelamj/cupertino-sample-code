/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Debugging macros the sample driver uses.
*/
#ifndef __NETWORKINGDRIVERKITDEBUG_H
#define __NETWORKINGDRIVERKITDEBUG_H

#include <stdint.h>

// Defined in NetworkingDriverKitSample.cpp
extern uint32_t ndks_debug;

enum {
    // Logging
    kNetworkingDriverkitDebugIOLog    = 0x00000001,
    kNetworkingDriverkitDebugError    = 0x00000080,
};

#define _CASSERT(x) _Static_assert(x, "compile-time assertion failed")

static inline const char *
__strrchr(const char *s, int c)
{
    const char *found = nullptr;
    do {
        if (*s == c) {
            found = s;
        }
    } while (*s++);
    return found;
}

#define UNLIKELY(x) __builtin_expect(!!((long)(x)), 0L)

#if DEVELOPMENT
#define __FILENAME__ (__strrchr(__FILE__, '/') ? __strrchr(__FILE__, '/') + 1 : __FILE__)

#define LOG(_fmt, ...)                                                       \
do {                                                                        \
    IOLog("%30s:%d %s " _fmt "\n", __FILENAME__, __LINE__, __func__, ##__VA_ARGS__); \
} while(0)

#define _FLOG(_flag, _fmt, ...) \
do { \
    if (1 || UNLIKELY(((_flag) && (ndks_debug & (_flag)) == (_flag)) || ((_flag) == kNetworkingDriverkitDebugError))) { \
        LOG(_fmt, ##__VA_ARGS__); \
    } \
} while (0)

#define FLOG(_flag, _fmt, ...) _FLOG((uint64_t)_flag, _fmt, ##__VA_ARGS__)
#define ELOG(_fmt, ...) FLOG(kNetworkingDriverkitDebugError, _fmt, ##__VA_ARGS__)
#define DLOG(_fmt, ...) FLOG(kNetworkingDriverkitDebugIOLog, _fmt, ##__VA_ARGS__)

#else // !DEVELOPMENT

#define LOG(_fmt, ...)
#define _FLOG(_flag, _fmt, ...)
#define FLOG(_flag, _fmt, ...)
#define ELOG(_fmt, ...)
#define DLOG(_fmt, ...)

#endif // !DEVELOPMENT

#endif /* ! __NETWORKINGDRIVERKITDEBUG_H */
