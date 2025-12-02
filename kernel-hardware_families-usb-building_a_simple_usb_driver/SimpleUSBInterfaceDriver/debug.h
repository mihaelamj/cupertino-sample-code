/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Debug interface for Sample USB interface driver.
*/


#ifndef _debug_h_
#define _debug_h_


#include <os/log.h>


enum debugMasks_t
{
    kSimpleUSBInterfaceDriverDebug_Always  = (1 << 0),       // 0x00000001
    kSimpleUSBInterfaceDriverDebug_Init    = (1 << 1),       // 0x00000002
    kSimpleUSBInterfaceDriverDebug_IO      = (1 << 2),      // 0x00000004
    kSimpleUSBInterfaceDriverDebug_Verbose = (1 << 3),       // 0x00000008
};


using constString_t = const char *const;

static constString_t constexpr
_trim (constString_t current,
       constString_t previous)
{
    if (*current == '\0') {
        // Found the end of the path, return the previous pointer
        return previous;
    }
    else if (*current == '/') {
        // Not the end of the path.  Restart the search from the next character after the '/'
        return _trim(current + 1, current + 1);
    }
    else {
        // Check if the next character is a delimiter (either '\0' or '/')
        return _trim(current + 1, previous);
    }
}


#define kFileName ({ constexpr constString_t _fileName { _trim(__FILE__, __FILE__) }; _fileName; })


/* Override a few macros from AssertMacros.h to allow passing in arguments as well as the format string */
#define require_action_string(assertion, exceptionLabel, action, string, ...) \
    do {                                                                      \
        if ( __builtin_expect(!(assertion), 0)) {                             \
            os_log(OS_LOG_DEFAULT,                                            \
                   "[%s:%d] Assertion failed: %s.  " string "\n",             \
                   kFileName,                                                 \
                   __LINE__,                                                  \
                   #assertion,                                                \
                   ##__VA_ARGS__);                                            \
            action;                                                           \
            goto exceptionLabel;                                              \
        }                                                                     \
    } while (0)


#define require_string(assertion, exceptionLabel, string, ...)    \
    do {                                                          \
        if ( __builtin_expect(!(assertion), 0)) {                 \
            os_log(OS_LOG_DEFAULT,                                \
                   "[%s:%d] Assertion failed: %s.  " string "\n", \
                   kFileName,                                     \
                   __LINE__,                                      \
                   #assertion,                                    \
                   ##__VA_ARGS__);                                \
            goto exceptionLabel;                                  \
        }                                                         \
    } while (0)


#define DEBUG_ASSERT_MESSAGE(name, assertion, label, message, file, line, value) \
    IOLog("Assertion failed: %s, %s file: %s, line: %d\n",                       \
          assertion, (message != 0) ? message : "", kFileName, line);


#define debugLog(mask, class, fmt, args...)                 \
    {                                                       \
        if (_debugLoggingMask & mask) {                     \
            IOLog("%s::%s: " fmt, #class, __func__,##args); \
        }                                                   \
    }


#include <AssertMacros.h>

#endif /* debug_h */

