/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for class with utilities to debug rendering.
*/

#import <Foundation/Foundation.h>
#import <simd/simd.h>
#import "AAPLConfig.h"

#if ENABLE_DEBUG_RENDERING
struct AAPLDebugMesh;

@protocol MTLDevice;
@protocol MTLRenderCommandEncoder;

// Encapsulates renderable objects for debug rendering.
//  Provides cone, cube and sphere primitives and an API for batching draws and
//  executing them with `renderInstances`.
@interface AAPLDebugRender : NSObject

// Initializes this renderer.
- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device;

- (void)renderDebugMesh:(const AAPLDebugMesh&)mesh
         viewProjMatrix:(matrix_float4x4)viewProjectionMatrix
            worldMatrix:(matrix_float4x4)worldMatrix
                  color:(simd::float4)color
              onEncoder:(nonnull id <MTLRenderCommandEncoder>)renderEncoder;

- (void)renderInstances:(nonnull id <MTLRenderCommandEncoder>)renderEncoder
         viewProjMatrix:(matrix_float4x4)viewProjMatrix;

- (void)renderSphereAt:(simd::float3)worldPosition
                radius:(float)radius
                 color:(simd::float4)color
             wireframe:(bool)wireframe;

- (void)renderCubeAt:(simd::float4x4)worldMatrix
               color:(simd::float4)color
           wireframe:(bool)wireframe;

- (void)renderConeAt:(simd::float4x4)worldMatrix
               color:(simd::float4)color
           wireframe:(bool)wireframe;

// Debug meshes for `renderDebugMesh`.
@property (readonly) AAPLDebugMesh &coneMesh;
@property (readonly) AAPLDebugMesh &cubeMesh;
@property (readonly) AAPLDebugMesh &sphereMesh;

@end
#endif
