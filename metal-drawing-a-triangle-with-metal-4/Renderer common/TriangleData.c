/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A type and a function implementation that configures the color and position data
 for the three vertices of a triangle.
*/

#include "TriangleData.h"
#include <string.h>

/// A four-component red color.
const simd_float4 red = { 1.0, 0.0, 0.0, 1.0 };

/// A four-component green color.
const simd_float4 green = { 0.0, 1.0, 0.0, 1.0 };

/// A four-component blue color.
const simd_float4 blue = { 0.0, 0.0, 1.0, 1.0 };


/// Configures an equilateral triangle's vertex data.
///
/// The function assigns:
/// - Red, green, and blue, to the first, second, and third vertices, respectively
/// - The positions along on a circle that circumscribes the triangle,
/// which are 120° apart from each other
///
/// - Parameters:
///   - radius: The radius of the circle that circumscribes the equilateral triangle.
///   - rotationInDegrees: An angle of rotation for the triangle, in degrees.
///   - triangleData: A pointer to a triangle data instance.
void triangleRedGreenBlue(float radius,
                          float rotationInDegrees,
                          TriangleData *triangleData)
{
    /// An angle, in radians, that's equal to the rotation.
    const float angle0 = (float)rotationInDegrees * M_PI / 180.0f;

    /// An angle, in radians, one-third of a circle more than the previous angle.
    ///
    /// This is the equivalent of adding 120° to the first angle.
    const float angle1 = angle0 + (2.0f * M_PI  / 3.0f);

    /// An angle, in radians, one-third of a circle more than the previous angle.
    ///
    /// This is the equivalent of adding 240° to the first angle.
    const float angle2 = angle0 + (4.0f * M_PI  / 3.0f);

    /// The position of the triangle's first vertex.
    simd_float2 position0 = {
        radius * cosf(angle0),
        radius * sinf(angle0)
    };

    /// The position of the triangle's second vertex.
    simd_float2 position1 = {
        radius * cosf(angle1),
        radius * sinf(angle1)
    };

    /// The position of the triangle's third vertex.
    simd_float2 position2 = {
        radius * cosf(angle2),
        radius * sinf(angle2)
    };

    // The triangle's red, bottom-right vertex.
    triangleData->vertex0.color = red;
    triangleData->vertex0.position = position0;

    // The triangle's green, bottom-left vertex.
    triangleData->vertex1.color = green;
    triangleData->vertex1.position = position1;

    // The triangle's blue, top-center vertex.
    triangleData->vertex2.color = blue;
    triangleData->vertex2.position = position2;
}

/// Configures an equilateral triangle's vertex data
/// and copies the bytes into a Metal buffer's pointer.
///
/// - Parameters:
///   - rotationInDegrees: An angle of rotation for the triangle, in degrees.
///   - bufferContents: A pointer from an `MTLBuffer` instance's `contents` property.
void configureVertexDataForBuffer(long rotationInDegrees,
                                  void *bufferContents)
{
    const short radius = 350;
    const short angle = rotationInDegrees % 360;

    TriangleData triangleData;
    triangleRedGreenBlue(radius, (float)angle, &triangleData);

    // Update the buffer that stores the triangle data.
    memcpy(bufferContents, &triangleData, sizeof(TriangleData));
}
