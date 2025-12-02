/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of classes storing information about the lighing enviroment of the scene.
*/

#import <Foundation/Foundation.h>
#import "AAPLLightingEnvironment.h"

using namespace simd;

#define LIGHT_ENV_DAY     (0)
#define LIGHT_ENV_EVENING (1)
#define LIGHT_ENV_NIGHT   (2)
#define LIGHT_ENV_COUNT   (3)

#define INITIAL_LIGHT_ENV (LIGHT_ENV_NIGHT)

// Helper function to interpolate between lighting environments.
static AAPLLightingEnvironment interpolateLightingEnvironment(uint envA, uint envB, float val, const AAPLLightingEnvironment* lightEnvs)
{
    AAPLLightingEnvironment env;
    env.exposure            = lightEnvs[envA].exposure * (1.0f - val) + lightEnvs[envB].exposure * val;
    env.sunColor            = lightEnvs[envA].sunColor * (1.0f - val) + lightEnvs[envB].sunColor * val;
    env.sunIntensity        = lightEnvs[envA].sunIntensity * (1.0f - val) + lightEnvs[envB].sunIntensity * val;
    env.skyColor            = lightEnvs[envA].skyColor * (1.0f - val) + lightEnvs[envB].skyColor * val;
    env.skyIntensity        = lightEnvs[envA].skyIntensity * (1.0f - val) + lightEnvs[envB].skyIntensity * val;
    env.localLightIntensity = lightEnvs[envA].localLightIntensity * (1.0f - val) + lightEnvs[envB].localLightIntensity * val;
    env.iblScale            = lightEnvs[envA].iblScale * (1.0f - val) + lightEnvs[envB].iblScale * val;
    env.iblSpecularScale    = lightEnvs[envA].iblSpecularScale * (1.0f - val) + lightEnvs[envB].iblSpecularScale * val;
    env.emissiveScale       = lightEnvs[envA].emissiveScale * (1.0f - val) + lightEnvs[envB].emissiveScale * val;
    env.scatterScale        = lightEnvs[envA].scatterScale * (1.0f - val) + lightEnvs[envB].scatterScale * val;
    env.wetness             = lightEnvs[envA].wetness * (1.0f - val) + lightEnvs[envB].wetness * val;

    return env;
}

@implementation AAPLLightingEnvironmentState
{
    // A range of lighting environments.
    AAPLLightingEnvironment _lightingEnvironments[LIGHT_ENV_COUNT];

    AAPLLightingEnvironment _currentLightingEnvironment;

    // Interpolation between loghting environments.
    uint                    _currentLightingEnvironmentA;
    uint                    _currentLightingEnvironmentB;
    float                   _currentLightingEnvironmentInterp;
}

-(AAPLLightingEnvironment) currentEnvironment
{
    return _currentLightingEnvironment;
}

-(NSUInteger) count
{
    return LIGHT_ENV_COUNT;
}

-(nonnull instancetype)init
{
    self = [super init];
    if(self)
    {
        _lightingEnvironments[LIGHT_ENV_DAY].exposure               = 0.3f;
        _lightingEnvironments[LIGHT_ENV_DAY].sunColor               = float3{1.0f, 1.0f, 1.0f};
        _lightingEnvironments[LIGHT_ENV_DAY].sunIntensity           = 10.0f;
        _lightingEnvironments[LIGHT_ENV_DAY].skyColor               = float3{65, 135, 255} / 255.0f;
        _lightingEnvironments[LIGHT_ENV_DAY].skyIntensity           = 2.0f;
        _lightingEnvironments[LIGHT_ENV_DAY].localLightIntensity    = 0.0f;
        _lightingEnvironments[LIGHT_ENV_DAY].iblScale               = 1.0f;
        _lightingEnvironments[LIGHT_ENV_DAY].iblSpecularScale       = 4.0f;
        _lightingEnvironments[LIGHT_ENV_DAY].emissiveScale          = 0.0f;
        _lightingEnvironments[LIGHT_ENV_DAY].scatterScale           = 0.5f;
        _lightingEnvironments[LIGHT_ENV_DAY].wetness                = 0.0f;
        // ----------------------------------
        _lightingEnvironments[LIGHT_ENV_EVENING].exposure               = 0.3f;
        _lightingEnvironments[LIGHT_ENV_EVENING].sunColor               = float3{1.0f, 0.5f, 0.15f};
        _lightingEnvironments[LIGHT_ENV_EVENING].sunIntensity           = 10.0f;
        _lightingEnvironments[LIGHT_ENV_EVENING].skyColor               = float3{200, 135, 255} / 255.0f;
        _lightingEnvironments[LIGHT_ENV_EVENING].skyIntensity           = 1.0f;
        _lightingEnvironments[LIGHT_ENV_EVENING].localLightIntensity    = 0.0f;
        _lightingEnvironments[LIGHT_ENV_EVENING].iblScale               = 0.5f;
        _lightingEnvironments[LIGHT_ENV_EVENING].iblSpecularScale       = 4.0f;
        _lightingEnvironments[LIGHT_ENV_EVENING].emissiveScale          = 0.0f;
        _lightingEnvironments[LIGHT_ENV_EVENING].scatterScale           = 1.0f;
        _lightingEnvironments[LIGHT_ENV_EVENING].wetness                = 0.0f;
        // ----------------------------------
        _lightingEnvironments[LIGHT_ENV_NIGHT].exposure             = 0.3f;
        _lightingEnvironments[LIGHT_ENV_NIGHT].sunColor             = float3{1.0f, 1.0f, 1.0f};
        _lightingEnvironments[LIGHT_ENV_NIGHT].sunIntensity         = 1.0f;
        _lightingEnvironments[LIGHT_ENV_NIGHT].skyColor             = float3{0, 35, 117} / 255.0f;
        _lightingEnvironments[LIGHT_ENV_NIGHT].skyIntensity         = 1.0f;
        _lightingEnvironments[LIGHT_ENV_NIGHT].localLightIntensity  = 1.0f;
        _lightingEnvironments[LIGHT_ENV_NIGHT].iblScale             = 0.1f;
        _lightingEnvironments[LIGHT_ENV_NIGHT].iblSpecularScale     = 4.0f;
        _lightingEnvironments[LIGHT_ENV_NIGHT].emissiveScale        = 10.0f;
        _lightingEnvironments[LIGHT_ENV_NIGHT].scatterScale         = 2.0f;
        _lightingEnvironments[LIGHT_ENV_NIGHT].wetness              = 1.0f;

        _currentLightingEnvironmentA        = INITIAL_LIGHT_ENV;
        _currentLightingEnvironmentB        = INITIAL_LIGHT_ENV;
        _currentLightingEnvironmentInterp   = 0.0f;
        _currentLightingEnvironment         = _lightingEnvironments[INITIAL_LIGHT_ENV];
    }

    return self;
}

-(void) next
{
    _currentLightingEnvironmentA = (_currentLightingEnvironmentA + 1) % LIGHT_ENV_COUNT;
    _currentLightingEnvironmentB = _currentLightingEnvironmentA;
    _currentLightingEnvironmentInterp = 0.0f;

    assert(_currentLightingEnvironmentA < LIGHT_ENV_COUNT);
    assert(_currentLightingEnvironmentB < LIGHT_ENV_COUNT);
}

-(void) update
{
    _currentLightingEnvironment = interpolateLightingEnvironment(_currentLightingEnvironmentA, _currentLightingEnvironmentB, _currentLightingEnvironmentInterp, _lightingEnvironments);
}

-(void) set:(float)interp a:(uint)a b:(uint)b
{
    _currentLightingEnvironmentA = a;
    _currentLightingEnvironmentB = b;
    _currentLightingEnvironmentInterp = interp;
}

@end
