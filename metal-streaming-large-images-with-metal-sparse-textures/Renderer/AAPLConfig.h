/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header containing the build time configuration settings.
*/

#pragma once

/// Use this define to turn on and off the residency visualization.
#define DEBUG_SPARSE_TEXTURE          (1)

/// Use this define to update the texture in parallel with the main thread.
#define ASYNCHRONOUS_TEXTURE_UPDATES  (1)

/// Use this define to use a smaller heap size that exaggerates the mapping and unmapping process.
#define USE_SMALL_SPARSE_TEXTURE_HEAP (0)

static const NSUInteger AAPLMaxFramesInFlight = 3l;
static const NSUInteger AAPLMaxStreamingBufferHeapInstCount = 64;
