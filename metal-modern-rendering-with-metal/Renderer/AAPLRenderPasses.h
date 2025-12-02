/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Types for tracking render passes.
*/

#import <Foundation/Foundation.h>

// Enumerates the range of supported render pass types.
//  These passes need to be handled by renderer implementations.
typedef NS_ENUM(uint32_t, AAPLRenderPass)
{
    AAPLRenderPassDepth,                // Depth only opaque geometry.
    AAPLRenderPassDepthAlphaMasked,     // Depth only alpha-masked geometry.
    AAPLRenderPassGBuffer,              // G-buffer fill opaque geometry.
    AAPLRenderPassGBufferAlphaMasked,   // G-buffer fill alpha-masked geometry.
    AAPLRenderPassForward,              // Forward render opaque geometry.
    AAPLRenderPassForwardAlphaMasked,   // Forward render alpha-masked geometry.
    AAPLRenderPassForwardTransparent,   // Forward render transparent geometry.

    AAPLRenderPassCount,
};
