/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines communal types and enumeration constants that the project's source and Metal shaders share.
*/

#ifndef AAPLShaderTypes_h
#define AAPLShaderTypes_h

#ifdef __METAL_VERSION__
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#define constant
#ifndef __cplusplus
#define constexpr const
#endif
#endif

#include <simd/simd.h>

/// Defines the size of the 3D object grid along the x-axis.
static constant constexpr size_t AAPLNumObjectsX = 4;

/// Defines the size of the 3D object grid along the y-axis.
static constant constexpr size_t AAPLNumObjectsY = 3;

/// Defines the size of the 3D object grid along the z-axis.
static constant constexpr size_t AAPLNumObjectsZ = 64;

/// Defines the total number of 3D objects in the grid.
static constant constexpr size_t AAPLNumObjectsXYZ = AAPLNumObjectsX * AAPLNumObjectsY * AAPLNumObjectsZ;

//  This structure defines the layout of vertices sent to the vertex
//  shader. This header is shared between the .metal shader and C code, to guarantee that
//  the layout of the vertex array in the C code matches the layout that the .metal
//  vertex shader expects.
typedef struct
{
    vector_float2 position;
    vector_float4 color;
} AAPLVertex;

typedef enum BufferIndex : NSInteger
{
    AAPLBufferIndexPositions = 0,
    AAPLBufferIndexFrameData = 1,
    AAPLBufferIndexMeshIndex = 2,
} BufferIndex;

typedef enum AAPLVisibilityTestingMode : NSInteger
{
    AAPLFragmentCountingMode = 0,
    AAPLOcclusionCullingMode = 1
} AAPLVisibilityTestingMode;

typedef struct
{
    matrix_float4x4 modelViewMatrix;
    matrix_float4x4 modelViewProjMatrix;
    vector_float3 color;
} AAPLFrameDataPerObject;

typedef struct
{
    AAPLFrameDataPerObject objects[AAPLNumObjectsXYZ];
} AAPLFrameData;

#endif /* AAPLShaderTypes_h */
