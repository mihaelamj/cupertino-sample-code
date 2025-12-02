/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A type and a function declaration that configures the color and position data
 for the three vertices of a triangle.
*/

#ifndef TriangleData_h
#define TriangleData_h

#include "ShaderTypes.h"

/// A type that stores the vertex data for one triangle.
typedef struct TriangleData {
    VertexData vertex0;
    VertexData vertex1;
    VertexData vertex2;
}
TriangleData;

/// Configures an equilateral triangle's vertex data
/// and copies the bytes into a Metal buffer's pointer.
///
/// - Parameters:
///   - rotationInDegrees: An angle of rotation for the triangle, in degrees.
///   - bufferContents: A pointer from an `MTLBuffer` instance's `contents` property.
void configureVertexDataForBuffer(long rotationInDegrees,
                                  void *bufferContents);
#endif /* TriangleData_h */
