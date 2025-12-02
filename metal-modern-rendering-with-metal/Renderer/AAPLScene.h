/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for class managing objects in the 3D scene.
*/

#import <Foundation/Foundation.h>
#import <simd/types.h>

@class AAPLCamera;
@class AAPLRenderer;
@protocol MTLDevice;
@protocol MTLBuffer;
typedef struct AAPLPointLightData AAPLPointLightData;
typedef struct AAPLSpotLightData AAPLSpotLightData;

// Contains additional data to be used when rendering the scene.
//  This includes lights and occluder geometry.
@interface AAPLScene : NSObject

// Initialization.
- (nonnull instancetype) initWithDevice:(nonnull id<MTLDevice>)device;

// Functions to add lights to the scene.
- (void)addPointLight:(simd::float3)position
                radius:(float)radius
                 color:(simd::float3)color
                 flags:(uint)flags;

- (void)addSpotLight:(simd::float3)pos
                  dir:(simd::float3)dir
               height:(float)height
                angle:(float)angle
                color:(simd::float3)color
                flags:(uint)flags;

- (void) clearLights;

//------------

@property (nonatomic) NSString* _Nonnull    meshFilename;

@property (nonatomic) simd::float3          cameraPosition;
@property (nonatomic) simd::float3          cameraDirection;
@property (nonatomic) simd::float3          cameraUp;

@property (nonatomic) NSString* _Nonnull    cameraKeypointsFilename;

@property (nonatomic) simd::float3          sunDirection;

// Lights in the scene.
@property (nonatomic, readonly) AAPLPointLightData* _Nonnull pointLights;
@property (nonatomic, readonly) AAPLSpotLightData*  _Nonnull spotLights;

@property (nonatomic, readonly) NSUInteger pointLightCount;
@property (nonatomic, readonly) NSUInteger spotLightCount;

// Occluder geometry for the scene.
@property (nonatomic, readonly) id<MTLBuffer> _Nonnull occluderVertexBuffer;
@property (nonatomic, readonly) id<MTLBuffer> _Nonnull occluderIndexBuffer;

//------------

// Serialization.
- (void) saveToFile:(nullable NSString*)name;
- (bool) loadFromFile:(nonnull NSString*)name altSource:(BOOL)altSource;

@end
