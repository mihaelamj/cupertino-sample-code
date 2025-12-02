/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the custom view class, which receives keyboard events.
*/
#pragma once

#if TARGET_MACOS

@import Foundation;
@import MetalKit;
@import Carbon;

/// This custom view class allows us to handle keyboard events.
@interface AAPLView : MTKView
@end

#endif
