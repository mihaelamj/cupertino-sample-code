/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for types loaded as part of the Mesh type.
*/
#import <simd/simd.h>

// 3-dimensional floating point bounding box, usable in both Metal Shading Language and C++.
struct AAPLBoundingBox3
{
    // Constructors.
    AAPLBoundingBox3() {}
    AAPLBoundingBox3(simd::float3 inMin, simd::float3 inMax)
        : min(inMin)
        , max(inMax) {}

    // Checks if this box contains the specified point.
    bool contains(simd::float3 pos) const
    {
        return simd::all(pos > min) && simd::all(pos < max);
    }

    // Center of this box.
    simd::float3 Center() const
    {
        return (min+max) * 0.5f;
    }

    // Converts a 3-bit index into a corner.
    simd::float3 GetCorner(uint index) const
    {
        return (simd::float3)
        {
            (index & 0b100) ? min.x : max.x,
            (index & 0b010) ? min.y : max.y,
            (index & 0b001) ? min.z : max.z
        };
    }

    // Encapsulates another bounding box into this.
    void Encapsulate(AAPLBoundingBox3 inBox)
    {
        min = simd::min(inBox.min, min);
        max = simd::max(inBox.max, max);
    }

    // Encapsulates a point into this bounding box.
    void Encapsulate(simd::float3 inPoint)
    {
        min = simd::min(inPoint, min);
        max = simd::max(inPoint, max);
    }

    // Constructs an empty bounding box.
    static AAPLBoundingBox3 sEmpty()
    {
        return AAPLBoundingBox3((simd::float3) { FLT_MAX, FLT_MAX, FLT_MAX}, (simd::float3) {-FLT_MAX, -FLT_MAX, -FLT_MAX});
    }

    simd::float3 min;
    simd::float3 max;
};

// 3-dimensional floating point sphere, usable in both Metal Shading Language and C++.
struct AAPLSphere
{
    // Constructors.
    AAPLSphere()                                    {}
    AAPLSphere(simd::float3 position, float radius) { data = (simd::float4) { position.x, position.y, position.z, radius }; }

    float distanceToPlane(simd::float4 planeEq) const
    {
        float centerDist = simd::dot(planeEq, simd::float4{data.x,data.y,data.z,1});
        return centerDist > 0 ? simd::max(0.0f, centerDist - data.w) : simd::min(0.0f, centerDist + data.w);
    }

    union
    {
        //xy = upper left, zw = lower right; named "data" to force accessor use.
        simd::float4 data;
        simd::float3        center;
        struct
        {
            float           centerxyz[3];
            float           radius;
        };
    };
};

// Metadata describing a chunk of an AAPLSubMesh, usable in both metal and C.
struct AAPLMeshChunk
{
    // Constructors.
    AAPLMeshChunk()
        : indexBegin(0)
        , indexCount(0)
        , boundingBox(AAPLBoundingBox3::sEmpty())
        , normalDistribution((simd::float4) {0,0,0,0}) {}
    AAPLMeshChunk(unsigned int begin, unsigned int count)
        : indexBegin(begin)
        , indexCount(count)
        , boundingBox(AAPLBoundingBox3::sEmpty())
        , normalDistribution((simd::float4) {0,0,0,0}) {}

    AAPLBoundingBox3    boundingBox;            // Sphere that bounds geometry in this chunk.

    simd::float4        normalDistribution;     // xyz = average angle; w = cos(maxphi)

    simd::float4        clusterMean;            // Only used for debugging the clustering;
                                                //   xyz = cluster mean in obj space; w = unused

    AAPLSphere          boundingSphere;         // Sphere that bounds geometry in this chunk.

    uint32_t            materialIndex;          // Index of the material in the materials array for
                                                //   GPU access. Duplicated from AAPLSubMesh.
    unsigned int        indexBegin;             // Offset in mesh index buffer to the indices for this. chunk.
    unsigned int        indexCount;             // Number of indices for this chunk in mesh index buffer.
};

// A SubMesh represents a group of chunks that share a material.
//  The indices for the chunks in this submesh are contiguous in the index
//  buffer.
struct AAPLSubMesh
{
    uint32_t            materialIndex;          // Material index for this submesh.

    AAPLBoundingBox3    boundingBox;            // Combined bounding box for the chunks in this submesh.
    AAPLSphere          boundingSphere;         // Combined bounding sphere for the chunks in this. submesh.

    unsigned int        indexBegin;             // Offset in mesh index buffer to the indices for this. submesh.
    unsigned int        indexCount;             // Number of indices for this submesh in mesh index. buffer.

    unsigned int        chunkStart;             // Offset in mesh index buffer to the chunks for this. submesh.
    unsigned int        chunkCount;             // Number of chunks for this submesh in mesh index buffer.
};
