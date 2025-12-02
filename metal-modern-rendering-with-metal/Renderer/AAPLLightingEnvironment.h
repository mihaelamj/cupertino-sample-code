/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for classes storing information about the lighing enviroment of the scene.
*/

#import <simd/simd.h>

struct AAPLLightingEnvironment
{
    float           exposure;
    simd::float3    sunColor;
    float           sunIntensity;
    simd::float3    skyColor;
    float           skyIntensity;
    float           localLightIntensity;
    float           iblScale;
    float           iblSpecularScale;
    float           emissiveScale;
    float           scatterScale;
    float           wetness;
};

// Encapsulates a lighting environment for the scene, which can be interpolated
//  between 2 other lighting environments.
@interface AAPLLightingEnvironmentState : NSObject

// Initialize this state.
- (nonnull instancetype) init;

// Update the current lighting environment based on interpolation.
- (void)update;

// Skip to next lighting environment.
- (void)next;

// Configures the interpolation between environments a and b.
- (void)set:(float)interp a:(uint)a b:(uint)b;

// The current lighting environment.
@property (readonly) AAPLLightingEnvironment currentEnvironment;

@property (readonly) NSUInteger count;

@end
