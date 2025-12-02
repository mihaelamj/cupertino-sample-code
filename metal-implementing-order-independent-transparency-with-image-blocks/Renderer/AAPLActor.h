/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The actor class's header file.
*/

#import "AAPLShaderTypes.h"

@import MetalKit;

NS_ASSUME_NONNULL_BEGIN

@interface AAPLActor : NSObject

-(instancetype) initWithProperties:(vector_float4) color
                          position:(vector_float3) position
                          rotation:(vector_float3) rotation
                             scale:(vector_float3) scale;

@property(nonatomic) vector_float4 color;

@property(nonatomic) vector_float3 position;

@property(nonatomic) vector_float3 rotation;

@property(nonatomic) vector_float3 scale;

@end

NS_ASSUME_NONNULL_END
