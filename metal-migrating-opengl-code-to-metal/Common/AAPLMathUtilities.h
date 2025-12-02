/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for vector, matrix, and quaternion math utility functions useful for 3D graphics rendering.
*/

#import <stdlib.h>
#import <simd/simd.h>

// Allow other libraries to overload their implementations of these functions
// because they are common.
#define AAPL_SIMD_OVERLOAD __attribute__((__overloadable__))

/// A quaternion type made of single-precision floating-point numbers.
typedef vector_float4 quaternion_float;

/// Returns a 32-bit floating-point number from a 16-bit floating-point number
/// that you cast to a 16-bit unsigned integer.
float AAPL_SIMD_OVERLOAD float32_from_float16(uint16_t i);

/// Returns a 16-bit floating-point number, which the function casts as a
/// 16-bit unsigned integer, from a 32-bit floating-point number.
uint16_t AAPL_SIMD_OVERLOAD float16_from_float32(float f);

/// Returns a value in degrees the function converts from a value in radians.
float AAPL_SIMD_OVERLOAD degrees_from_radians(float radians);

/// Returns a value in radians the function converts from a value in degrees.
float AAPL_SIMD_OVERLOAD radians_from_degrees(float degrees);

/// Generates a random floating-point value within a range.
inline static float AAPL_SIMD_OVERLOAD  random_float(float min, float max)
{
    return (((double)random()/RAND_MAX) * (max-min)) + min;
}

/// Generate a random three-component vector within a range.
vector_float3 AAPL_SIMD_OVERLOAD generate_random_vector(float min, float max);

/// Seeds the random number generator with a value.
void AAPL_SIMD_OVERLOAD seedRand(uint32_t seed);

/// Returns a random integer value from the random number generator.
int32_t AAPL_SIMD_OVERLOAD randi(void);

/// Returns a random floating-point value from the random number generator.
float AAPL_SIMD_OVERLOAD randf(float x);

/// Returns a 3D vector the function creates by linearly interpolating between
/// two 3D vectors.
vector_float3 AAPL_SIMD_OVERLOAD vector_lerp(vector_float3 v0, vector_float3 v1, float t);

/// Returns a 4D vector the function creates by linearly interpolating between
/// two 4D vectors.
vector_float4 AAPL_SIMD_OVERLOAD vector_lerp(vector_float4 v0, vector_float4 v1, float t);

/// Converts a 3x3 unit-norm quaternion into its corresponding rotation matrix.
matrix_float3x3 AAPL_SIMD_OVERLOAD matrix3x3_from_quaternion(quaternion_float q);

/// Constructs a 3x3 matrix from nine scalar values.
///
/// The function's parameters are in column-major order.
/// For example, the function assigns the first three parameters to the three rows,
/// in order, of the matrix's initial column.
/// The next three parameters correspond to the rows in the next column, and so on.
matrix_float3x3 AAPL_SIMD_OVERLOAD matrix_make_rows(float m00, float m10, float m20,
                                                    float m01, float m11, float m21,
                                                    float m02, float m12, float m22);

/// Constructs a 4x4 matrix from 16 scalar values.
///
/// The function's parameters are in column-major order.
/// For example, the function assigns the first four parameters to the four rows,
/// in order, of the matrix's initial column.
/// The next four parameters correspond to the rows in the next column, and so on.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix_make_rows(float m00, float m10, float m20, float m30,
                                                    float m01, float m11, float m21, float m31,
                                                    float m02, float m12, float m22, float m32,
                                                    float m03, float m13, float m23, float m33);

/// Constructs a 3x3 matrix from three 3D vectors.
matrix_float3x3 AAPL_SIMD_OVERLOAD matrix_make_columns(vector_float3 col0,
                                                       vector_float3 col1,
                                                       vector_float3 col2);

/// Constructs a 4x4 matrix from four 4D vectors.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix_make_columns(vector_float4 col0,
                                                       vector_float4 col1,
                                                       vector_float4 col2,
                                                       vector_float4 col3);

/// Constructs a 3x3 rotation matrix from an angle in radians and a 3D-axis vector.
matrix_float3x3 AAPL_SIMD_OVERLOAD matrix3x3_rotation(float radians, vector_float3 axis);

/// Constructs a 3x3 rotation matrix from an angle in radians and a 3D-axis as three scalar values.
matrix_float3x3 AAPL_SIMD_OVERLOAD matrix3x3_rotation(float radians, float x, float y, float z);

/// Constructs a 3x3 scaling matrix from three scale factors, one for each dimension.
matrix_float3x3 AAPL_SIMD_OVERLOAD matrix3x3_scale(float x, float y, float z);

/// Constructs a 3x3 scaling matrix from a 3D vector that represents the scale factors for each dimension.
matrix_float3x3 AAPL_SIMD_OVERLOAD matrix3x3_scale(vector_float3 s);

/// Returns the 3x3 matrix from the upper-left submatrix of a 4x4 matrix.
matrix_float3x3 AAPL_SIMD_OVERLOAD matrix3x3_upper_left(matrix_float4x4 m);

/// Returns the 3x3 matrix that is the inverse of the transpose of another matrix.
matrix_float3x3 AAPL_SIMD_OVERLOAD matrix_inverse_transpose(matrix_float3x3 m);

/// Constructs a homogeneous rotation matrix from quaternion that represent an rotation angle about an axis.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix4x4_from_quaternion(quaternion_float q);

/// Constructs a rotation matrix from an angle in radians and a 3D-axis vector.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix4x4_rotation(float radians, vector_float3 axis);

/// Constructs a rotation matrix from an angle in radians and a 3D-axis as three scalar values.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix4x4_rotation(float radians, float x, float y, float z);

/// Constructs a 4x4 identity matrix.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix4x4_identity(void);

/// Constructs a 4x4 scaling matrix from three scalar values, one for each dimension.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix4x4_scale(float sx, float sy, float sz);

/// Constructs a 4x4 scaling matrix from a 3D vector that's an array of scaling factors.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix4x4_scale(vector_float3 s);

/// Constructs a 4x4 translation matrix from three scalar values, one for each dimension.
///
/// The 4x4 matrix represents a 3D translation along the vector `(tx, ty, tz)`.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix4x4_translation(float tx, float ty, float tz);

/// Constructs a 4x4 translation matrix from a 3D vector.
///
/// The 4x4 matrix represents a 3D translation along the vector `(t.x, t.y, t.z)`.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix4x4_translation(vector_float3 t);

/// Constructs a 4x4 matrix that scales and translates from two 3D vectors.
///
/// The 4x4 matrix represents a 3D scaling factor by the vector `(s.x, s.y, s.z)`,
/// and a translation along the vector `(t.x, t.y, t.z)`.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix4x4_scale_translation(vector_float3 s, vector_float3 t);

/// Constructs a 4x4 view matrix based in a left-hand coordinate system from nine scalars.
///
/// The matrix represents a view at the position `(eyeX, eyeY, eyeZ)` that
/// looks toward `(centerX, centerY, centerZ)` with an up-vector `(upX, upY, upZ)`.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix_look_at_left_hand(float eyeX, float eyeY, float eyeZ,
                                                            float centerX, float centerY, float centerZ,
                                                            float upX, float upY, float upZ);

/// Constructs a 4x4 view matrix based in a left-hand coordinate system from three 3D vectors.
///
/// The matrix represents a view at the position `eye` that
/// looks toward `target` with an up-vector `up`.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix_look_at_left_hand(vector_float3 eye,
                                                            vector_float3 target,
                                                            vector_float3 up);

/// Constructs a 4x4 view matrix based in a right-hand coordinate system from nine scalars.
///
/// The matrix represents a view at the position `(eyeX, eyeY, eyeZ)` that
/// looks toward `(centerX, centerY, centerZ)` with an up-vector `(upX, upY, upZ)`.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix_look_at_right_hand(float eyeX, float eyeY, float eyeZ,
                                                             float centerX, float centerY, float centerZ,
                                                             float upX, float upY, float upZ);

/// Constructs a 4x4 view matrix based in a right-hand coordinate system from three 3D vectors.
///
/// The matrix represents a view at the position `eye` that
/// looks toward `target` with an up-vector `up`.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix_look_at_right_hand(vector_float3 eye,
                                                             vector_float3 target,
                                                             vector_float3 up);

/// Constructs a 4x4 symmetric orthographic-projection matrix, from left-hand eye
/// coordinates to left-hand clip coordinates.
///
/// The projection matrix maps:
///
/// - The left, top corner to `(-1, 1)`
/// - The right, bottom corner to `(1, -1)`
/// - The nearZ, farZ corner to `(0, 1)`
///
/// The first four arguments are signed-eye coordinates.
/// The `nearZ` and `farZ` parameters are absolute distances
/// from the eye to the near and far clip planes.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix_ortho_left_hand(float left, float right, float bottom, float top, float nearZ, float farZ);

/// Constructs a 4x4 symmetric orthographic-projection matrix, from right-hand eye
/// coordinates to right-hand clip coordinates.
///
/// The projection matrix maps:
///
/// - The left, top corner to `(-1, 1)`
/// - The right, bottom corner to `(1, -1)`
/// - The nearZ, farZ corner to `(0, 1)`
///
/// The first four arguments are signed-eye coordinates.
/// The `nearZ` and `farZ` parameters are absolute distances
/// from the eye to the near and far clip planes.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix_ortho_right_hand(float left, float right, float bottom, float top, float nearZ, float farZ);

/// Constructs a 4x4 symmetric perspective-projection matrix, from left-hand eye
/// coordinates to left-hand clip coordinates.
///
/// The function gives the matrix a vertical viewing angle of `fovyRadians`,
/// an aspect ratio of `aspect`, and absolute near and far distances from the eye
/// along the z-axis based on the `nearZ`, and `farZ` parameters, respectively.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix_perspective_left_hand(float fovyRadians, float aspect, float nearZ, float farZ);

/// Constructs a 4x4 symmetric perspective-projection matrix, from right-hand eye
/// coordinates to right-hand clip coordinates.
///
/// The function gives the matrix a vertical viewing angle of `fovyRadians`,
/// an aspect ratio of `aspect`, and absolute near and far distances from the eye
/// along the z-axis based on the `nearZ`, and `farZ` parameters, respectively.
matrix_float4x4  AAPL_SIMD_OVERLOAD matrix_perspective_right_hand(float fovyRadians, float aspect, float nearZ, float farZ);

/// Construct a 4x4 general frustum-projection matrix, from right-hand eye
/// coordinates to left-hand clip coordinates.
///
/// The `left`, `right`, `bottom`, and `top` parameters are signed-eye coordinates
/// that define the visible frustum at the near clip plane.
/// The `nearZ` and `farZ` parameters are absolute distances from the eye to the
/// near and far clip planes, respectively.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix_perspective_frustum_right_hand(float left, float right, float bottom, float top, float nearZ, float farZ);

/// Returns the 4x4 matrix that is the inverse of the transpose of another matrix.
matrix_float4x4 AAPL_SIMD_OVERLOAD matrix_inverse_transpose(matrix_float4x4 m);

/// Constructs an identity quaternion.
quaternion_float AAPL_SIMD_OVERLOAD quaternion_identity(void);

/// Constructs a quaternion from four scalar values.
///
/// The parameters define a quaternion of the form `w + xi + yj + zk`.
quaternion_float AAPL_SIMD_OVERLOAD quaternion(float x, float y, float z, float w);

/// Constructs a quaternion from a 3D vector and a scalar.
///
/// The parameters define a quaternion of the form `w + v.x*i + v.y*j + v.z*k`.
quaternion_float AAPL_SIMD_OVERLOAD quaternion(vector_float3 v, float w);

/// Constructs a unit-norm quaternion that represents a rotation about a 3D axis
/// from scalar values for the angle and the axis.
quaternion_float AAPL_SIMD_OVERLOAD quaternion(float radians, float x, float y, float z);

/// Constructs a unit-norm quaternion that represents a rotation about a 3D axis
/// from a scalar value for the angle and a 3D vector for the axis.
quaternion_float AAPL_SIMD_OVERLOAD quaternion(float radians, vector_float3 axis);

/// Constructs a unit-norm quaternion from a 3x3 matrix that represents a rotation.
///
/// The return value is only valid for matrices that represent a pure rotation.
quaternion_float AAPL_SIMD_OVERLOAD quaternion(matrix_float3x3 m);

/// Constructs a unit-norm quaternion from a 4x4 matrix that represents a rotation.
///
/// The return value is only valid for matrices that represent a pure rotation.
quaternion_float AAPL_SIMD_OVERLOAD quaternion(matrix_float4x4 m);

/// Returns the length of a quaternion.
float AAPL_SIMD_OVERLOAD quaternion_length(quaternion_float q);

/// Returns the square of the length of a quaternion.
float AAPL_SIMD_OVERLOAD quaternion_length_squared(quaternion_float q);

/// Returns the rotation axis of a unit-norm quaternion.
vector_float3 AAPL_SIMD_OVERLOAD quaternion_axis(quaternion_float q);

/// Returns the rotation angle of a unit-norm quaternion.
float AAPL_SIMD_OVERLOAD quaternion_angle(quaternion_float q);

/// Returns a quaternion from a rotation axis and an angle, in radians.
quaternion_float AAPL_SIMD_OVERLOAD quaternion_from_axis_angle(vector_float3 axis, float radians);

/// Returns a quaternion from a 3x3 rotation matrix.
quaternion_float AAPL_SIMD_OVERLOAD quaternion_from_matrix3x3(matrix_float3x3 m);

/// Returns a quaternion from an Euler angle, in radians.
quaternion_float AAPL_SIMD_OVERLOAD quaternion_from_euler(vector_float3 euler);

/// Returns a unit-norm quaternion.
quaternion_float AAPL_SIMD_OVERLOAD quaternion_normalize(quaternion_float q);

/// Returns the inverse quaternion of another quaternion.
quaternion_float AAPL_SIMD_OVERLOAD quaternion_inverse(quaternion_float q);

/// Returns the conjugate quaternion of another quaternion.
quaternion_float AAPL_SIMD_OVERLOAD quaternion_conjugate(quaternion_float q);

/// Returns a quaternion that's the product of two quaternions.
quaternion_float AAPL_SIMD_OVERLOAD quaternion_multiply(quaternion_float q0, quaternion_float q1);

/// Returns a quaternion by spherically interpolating between two quaternions.
quaternion_float AAPL_SIMD_OVERLOAD quaternion_slerp(quaternion_float q0, quaternion_float q1, float t);

/// Returns a vector by rotating another vector with a unit-norm quaternion.
vector_float3 AAPL_SIMD_OVERLOAD quaternion_rotate_vector(quaternion_float q, vector_float3 v);

/// Returns a quaternion from a forward vector and an up vector for right-hand coordinate systems.
quaternion_float AAPL_SIMD_OVERLOAD quaternion_from_direction_vectors_right_hand(vector_float3 forward, vector_float3 up);

/// Returns a quaternion from a forward vector and an up vector for left-hand coordinate systems.
quaternion_float AAPL_SIMD_OVERLOAD quaternion_from_direction_vectors_left_hand(vector_float3 forward, vector_float3 up);

/// Returns a vector in the positive direction along the z-axis of a quaternion.
vector_float3 AAPL_SIMD_OVERLOAD forward_direction_vector_from_quaternion(quaternion_float q);

/// Returns a vector in the positive direction along the y-axis of a quaternion.
///
/// You can convert the return-value vector between left- and right-handed
/// coordinate systems by negating it.
vector_float3 AAPL_SIMD_OVERLOAD up_direction_vector_from_quaternion(quaternion_float q);

/// Returns a vector in the positive direction along the x-axis of a quaternion.
///
/// You can convert the return-value vector between left- and right-handed
/// coordinate systems by negating it.
vector_float3 AAPL_SIMD_OVERLOAD right_direction_vector_from_quaternion(quaternion_float q);

