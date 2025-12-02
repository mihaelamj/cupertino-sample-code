/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for vector, matrix, and quaternion math utility functions useful for 3D graphics rendering.
*/

#pragma once

#define _USE_MATH_DEFINES
#import <simd/simd.h>
#import <math.h>

/// Constructs a 4 x 4 matrix with parameters specified in row-major order.
static inline
simd_float4x4 make_float4x4(float m11, float m12, float m13, float m14,
                            float m21, float m22, float m23, float m24,
                            float m31, float m32, float m33, float m34,
                            float m41, float m42, float m43, float m44)
{
    return (simd_float4x4) {{
        { m11, m21, m31, m41 }, // Column 1
        { m12, m22, m32, m42 }, // Column 2.
        { m13, m23, m33, m43 }, // Column 3.
        { m14, m24, m34, m44 }  // Column 4.
    }};
}

/// Returns a 4 x 4 identity matrix.
static inline
simd_float4x4 matrix4x4_identity(void) {
    return make_float4x4(1, 0, 0, 0,
                         0, 1, 0, 0,
                         0, 0, 1, 0,
                         0, 0, 0, 1);
}

/// Returns a 4 x 4 rotation matrix using the angle-axis parameters.
static inline
simd_float4x4 matrix4x4_rotation(float degrees, simd_float3 axis)
{
    float radians = degrees * M_PI / 180.0;
    axis = simd_normalize(axis);
    float ct = cosf(radians);
    float st = sinf(radians);
    float ci = 1 - ct;
    float x = axis.x, y = axis.y, z = axis.z;
    
    return make_float4x4(ct + x * x * ci, x * y * ci - z * st, x * z * ci + y * st, 0, // Row 1.
                         y * x * ci + z * st, ct + y * y * ci, y * z * ci - x * st, 0, // Row 2.
                         z * x * ci - y * st, z * y * ci + x * st, ct + z * z * ci, 0, // Row 3.
                         0, 0, 0, 1);                                                  // Row 4.
}

/// Returns a 4 x 4 translation matrix.
static inline
simd_float4x4 matrix4x4_translation(float tx, float ty, float tz)
{
    return make_float4x4(1, 0, 0, tx,
                         0, 1, 0, ty,
                         0, 0, 1, tz,
                         0, 0, 0, 1);
}

/// Returns a 4 x 4 scaling matrix.
static inline
simd_float4x4 matrix4x4_scaling(float sx, float sy, float sz)
{
    return make_float4x4(sx, 0, 0, 0,
                         0, sy, 0, 0,
                         0, 0, sz, 0,
                         0, 0, 0, 1);
}

/// Returns a perspective matrix.
static inline
simd_float4x4 matrix4x4_perspective_right_hand(float fovyRadians, float aspect, float nearZ, float farZ)
{
    float ys = 1 / tanf(fovyRadians * 0.5);
    float xs = ys / aspect;
    float zs = farZ / (nearZ - farZ);
    
    return make_float4x4(xs, 0, 0, 0,           // Row 1.
                         0, ys, 0, 0,           // Row 2.
                         0, 0, zs, nearZ * zs,  // Row 3.
                         0, 0, -1, 0);          // Row 4.
}

/// Returns radians converted from degrees.
static inline
double radiansFromDegrees(double degrees)
{
    return degrees * M_PI / 180.0;
}

/// Wraps `x` so that it's within the range `a` to `b`.
static inline
double fmodRange(double x, double a, double b)
{
    return fmod(x - a, b - a) + a;
}

/// Clamps `x` to the range `a` to `b`.
static inline
float fclamp(float x, float a, float b)
{
    if (x < a) {
        return a;
    } else if (x > b) {
        return b;
    } else {
        return x;
    }
}

/// Clamps `x` to the range `a` to `b`.
static inline
double dclamp(double x, double a, double b)
{
    if (x < a) {
        return a;
    } else if (x > b) {
        return b;
    } else {
        return x;
    }
}
