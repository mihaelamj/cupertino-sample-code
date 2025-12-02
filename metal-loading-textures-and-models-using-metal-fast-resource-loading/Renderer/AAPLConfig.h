/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header that contains the build time configuration settings.
*/

#pragma once

#include <AvailabilityMacros.h>

/// Use `MAC_OS_X_VERSION_MAX_ALLOWED` to detect whether MTLIO is available in the SDK.
#ifdef MAC_OS_VERSION_13_0
    #if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_VERSION_13_0
        #define AAPL_USE_MTLIO 1
    #else
        #define AAPL_USE_MTLIO 0
    #endif
#else
    #define AAPL_USE_MTLIO 0
#endif

/// Use this define to update the resources in parallel with the main thread.
#define AAPL_ASYNCHRONOUS_RESOURCE_UPDATES (0)
