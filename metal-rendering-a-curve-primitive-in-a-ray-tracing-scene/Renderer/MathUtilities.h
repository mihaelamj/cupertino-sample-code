/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for simple matrix math functions.
*/

#ifndef MathUtilities_h
#define MathUtilities_h

#import <Metal/Metal.h>
#include <simd/simd.h>

matrix_float4x4 matrix4x4_translation(float tx, float ty, float tz);
matrix_float4x4 matrix4x4_scale(float sx, float sy, float sz);

#endif /* MathUtilities_h */
