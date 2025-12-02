/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation for primitive 3D utility functions.
*/

#import "AAPLMeshTypes.h"
#import "AAPLShaderTypes.h"

#import <Foundation/Foundation.h>
#import <simd/types.h>

// Checks if a sphere is in a frustum.
inline bool sphereInFrustum(const AAPLCameraParams& cameraParams, const AAPLSphere& sphere)
{
    return (simd::min(
                      simd::min(sphere.distanceToPlane(cameraParams.worldFrustumPlanes[0]),
                                simd::min(sphere.distanceToPlane(cameraParams.worldFrustumPlanes[1]),
                                          sphere.distanceToPlane(cameraParams.worldFrustumPlanes[2]))),
                      simd::min(sphere.distanceToPlane(cameraParams.worldFrustumPlanes[3]),
                                simd::min(sphere.distanceToPlane(cameraParams.worldFrustumPlanes[4]),
                                          sphere.distanceToPlane(cameraParams.worldFrustumPlanes[5]))))) >= 0.0f;
}

