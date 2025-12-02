/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The types and enum constants the app shares with its Metal shaders and C/ObjC code.
*/

#ifndef ShaderTypes_h
#define ShaderTypes_h

#import <simd/simd.h>


/// Defines the binding index values for passing buffer arguments to GPU function parameters.
///
/// The binding values define an agreement between:
/// - The app's main code in Objective-C that submits the data to the GPU
/// - The shader code that defines the GPU functions, which receive the data through their parameters
///
/// The value needs to match between the two sides of exchange for the data to get
/// to the correct place.
typedef enum InputBufferIndex
{
    /// The buffer binding index value that stores the triangle's vertex data.
    ///
    /// The data at this binding index stores an array of three ``VertexData`` instances.
    InputBufferIndexForVertexData = 0,

    /// The buffer binding index value that stores the app's viewport's size.
    ///
    /// The vertex shader calculates the pixel coordinates of the triangle's vertices
    /// based on the size of the app's viewport.
    InputBufferIndexForViewportSize = 1,
} InputBufferIndex;

/// A type that defines the data layout for a triangle vertex,
/// which includes position and pixel-color values.
///
/// The app's main code and shader code apply this type for data layout consistency.
typedef struct
{
    /// The location for a vertex in 2D, pixel-coordinate space.
    ///
    /// For example, a value of `100` in either dimension means the vertex is
    /// 100 pixels from the origin in that dimension.
    simd_float2 position;

    /// A pixel-color value for a vertex.
    ///
    /// The color components are red, green, blue, and alpha.
    simd_float4 color;
} VertexData;

#endif /* ShaderTypes_h */
