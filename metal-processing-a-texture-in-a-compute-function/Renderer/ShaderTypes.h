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
/// The values need to match between both sides of the exchange for the data to get
/// to the correct place.
typedef enum BufferBindingIndex
{
    /// The buffer binding index value that stores the triangle's vertex data.
    ///
    /// The data at this binding index stores an array of three ``VertexData`` instances.
    BufferBindingIndexForVertexData = 0,

    /// The buffer binding index value that stores the app's viewport's size.
    ///
    /// The vertex shader calculates the pixel coordinates of the triangle's vertices
    /// based on the size of the app's viewport.
    BufferBindingIndexForViewportSize = 1,
} BufferBindingIndex;

/// Defines the binding index values for passing texture arguments to GPU function parameters.
///
/// The binding values define an agreement between:
/// - The app's main code in Objective-C that submits the data to the GPU
/// - The shader code that defines the GPU functions, which receive the data through their parameters
///
/// The values need to match between both sides of the exchange for the data to get
/// to the correct place.
typedef enum TextureBindingIndex
{
    /// An index of a color texture for a compute kernel in a compute pass.
    ComputeTextureBindingIndexForColorImage = 0,

    /// An index of a grayscale texture for a compute kernel in a compute pass.
    ComputeTextureBindingIndexForGrayscaleImage = 1,

    /// An index of a texture for a fragment shader in a render pass.
    RenderTextureBindingIndex = 0,
} TextureBindingIndex;

/// A type that defines the data layout for a triangle vertex,
/// which includes position and texture coordinate values.
///
/// The app's main code and shader code apply this type for data layout consistency.
typedef struct VertexData
{
    /// The location for a vertex in 2D, pixel-coordinate space.
    ///
    /// For example, a value of `100` in either dimension means the vertex is
    /// 100 pixels from the origin in that dimension.
    simd_float2 position;

    /// The location within a 2D texture for a vertex.
    simd_float2 textureCoordinate;
} VertexData;

#endif /* ShaderTypes_h */
