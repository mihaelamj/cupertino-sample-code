/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom renderer that conforms to the MTKViewDelegate protocol.
*/

#pragma once

#import <MetalKit/MetalKit.h>

@class AAPLCamera;

@interface AAPLRenderer : NSObject<MTKViewDelegate>

/// Initializes the view.
- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView*)view;

/// Loads the scene from the provided URL and prepares the camera.
- (void)setupScene:(nonnull NSString*)url;

/// Informs the draw method that a frame needs to be rendered.
- (void)requestFrame;

@property (nonatomic) bool isZUp;

@property (nonnull, nonatomic) AAPLCamera* viewCamera;

@end
