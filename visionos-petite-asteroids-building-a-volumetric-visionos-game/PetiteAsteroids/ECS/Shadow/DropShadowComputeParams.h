/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure containing the description of the drop shadow compute parameters for use in Metal compute shaders.
*/

#pragma once

#include <simd/simd.h>

struct DropShadowComputeParams {
    simd_float3 sourcePosition;
    float sourceShadowYPosition;
    float sourceShadowRadius;
};
