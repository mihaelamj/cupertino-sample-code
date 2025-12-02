/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Metal shaders to use for this sample.
*/
#include "ShaderTypes.h"

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

using namespace raytracing;

constant unsigned int primes[] = {
    2,   3,  5,  7,
    11, 13, 17, 19,
    23, 29, 31, 37,
    41, 43, 47, 53,
    59, 61, 67, 71,
    73, 79, 83, 89
};

// Returns the i'th element of the Halton sequence using the d'th prime number as a
// base.  The Halton sequence is a "low discrepency" sequence: the values appear
// random, but are more evenly distributed than a purely random sequence.  Each random
// value that renders the image needs to use a different independent dimension, `d`',
// and each sample (frame) needs to use a different index `i`.  To decorrelate each
// pixel, you can apply a random offset to `i`.
float halton(unsigned int i, unsigned int d)
{
    unsigned int b = primes[d];

    float f = 1.0f;
    float invB = 1.0f / b;

    float r = 0;

    while (i > 0) {
        f = f * invB;
        r = r + f * (i % b);
        i = i / b;
    }

    return r;
}

// Interpolates vertex attributes of an arbitrary type across the surface of a triangle
// given the barycentric coordinates and triangle index in an intersection structure.
template<typename T>
inline T interpolateVertexAttribute(device T *attributes, unsigned int primitiveIndex, float2 uv)
{
    // Look up the value for each vertex.
    T T0 = attributes[primitiveIndex * 3 + 0];
    T T1 = attributes[primitiveIndex * 3 + 1];
    T T2 = attributes[primitiveIndex * 3 + 2];

    // Compute the sum of vertex attributes weighted by barycentric coordinates.
    // Barycentric coordinates sum to one.
    return (1.0f - uv.x - uv.y) * T0 + uv.x * T1 + uv.y * T2;
}

// Uses the inversion method to map two uniformly random numbers to a three-dimensional
// unit hemisphere, where the probability of a given sample is proportional to the cosine
// of the angle between the sample direction and the "up" direction (0, 1, 0).
inline float3 sampleCosineWeightedHemisphere(float2 u)
{
    float phi = 2.0f * M_PI_F * u.x;

    float cos_phi;
    float sin_phi = sincos(phi, cos_phi);

    float cos_theta = sqrt(u.y);
    float sin_theta = sqrt(1.0f - cos_theta * cos_theta);

    return float3(sin_theta * cos_phi, cos_theta, sin_theta * sin_phi);
}

// Maps two uniformly random numbers to the surface of a two-dimensional area light
// source and returns the direction to this point, the amount of light that travels
// between the intersection point and the sample point on the light source, as well
// as the distance between these two points.
inline void sampleAreaLight(device AreaLight & light,
                            float2 u,
                            float3 position,
                            thread float3 & lightDirection,
                            thread float3 & lightColor,
                            thread float & lightDistance)
{
    // Map to -1..1.
    u = u * 2.0f - 1.0f;

    // Transform into the light's coordinate system.
    float3 samplePosition = light.position +
                            light.right * u.x +
                            light.up * u.y;

    // Compute the vector from the sample point on the light
    // source to the intersection point.
    lightDirection = samplePosition - position;

    lightDistance = length(lightDirection);

    float inverseLightDistance = 1.0f / max(lightDistance, 1e-3f);

    // Normalize the light direction.
    lightDirection *= inverseLightDistance;

    // Start with the light's color.
    lightColor = light.color;

    // Light falls off with the inverse square of the distance to the intersection point.
    lightColor *= (inverseLightDistance * inverseLightDistance);

    // Light also falls off with the cosine of angle between the intersection point and
    // the light source.
    lightColor *= saturate(dot(-lightDirection, light.forward));
}

// Aligns a direction on the unit hemisphere such that the hemisphere's "up" direction
// (0, 1, 0) maps to the given surface normal direction.
inline float3 alignHemisphereWithNormal(float3 sample, float3 normal)
{
    // Set the "up" vector to the normal.
    float3 up = normal;

    // Find an arbitrary direction perpendicular to the normal. This becomes the
    // "right" vector.
    float3 right = normalize(cross(normal, float3(0.0072f, 1.0f, 0.0034f)));

    // Find a third vector perpendicular to the previous two. This becomes the
    // "forward" vector.
    float3 forward = cross(right, up);

    // Map the direction on the unit hemisphere to the coordinate system aligned
    // with the normal.
    return sample.x * right + sample.y * up + sample.z * forward;
}

// The resources for a piece of triangle geometry.
struct KeyframeResources
{
    device float3 *vertexNormals;
    device float3 *vertexColors;
};

struct MeshResources
{
    device KeyframeResources *keyframes;
    unsigned int primitiveMotionKeyframeCount;
};

__attribute__((always_inline))
float3 transformPoint(float3 p, float4x3 transform)
{
    return transform * float4(p.x, p.y, p.z, 1.0f);
}

__attribute__((always_inline))
float3 transformDirection(float3 p, float4x3 transform)
{
    return normalize(transform * float4(p.x, p.y, p.z, 0.0f));
}

// The main ray tracing kernel. This uses a template because the system can
// change the tags easily at Metal shading language compile time.
template<typename accelerationStructureType, typename intersectorType>
kernel void raytracingKernel(uint2 tid [[thread_position_in_grid]],
                             constant FrameData & frameData,
                             texture2d<unsigned int> randomTex,
                             texture2d<float> prevTex,
                             texture2d<float, access::write> dstTex,
                             device MeshResources *resources,
                             device MTLAccelerationStructureMotionInstanceDescriptor *instances,
                             device AreaLight *areaLights,
                             accelerationStructureType accelerationStructure)
{
    // The sample aligns the thread count to the threadgroup size, which means the thread
    // count may be different than the bounds of the texture. Test to make sure this
    // thread is referencing a pixel within the bounds of the texture.
    if (tid.x < frameData.width && tid.y < frameData.height)
    {
        // The ray to cast.
        ray ray;

        // The pixel coordinates for this thread.
        float2 pixel = (float2)tid;

        // Apply a random offset to the random number index to decorrelate pixels.
        unsigned int offset = randomTex.read(tid).x;

        // Add a random offset to the pixel coordinates for antialiasing.
        float2 r = float2(halton(offset + frameData.frameIndex, 0),
                          halton(offset + frameData.frameIndex, 1));

        pixel += r;

        // Map pixel coordinates to -1..1.
        float2 uv = (float2)pixel / float2(frameData.width, frameData.height);
        uv = uv * 2.0f - 1.0f;

        constant Camera & camera = frameData.camera;

        // The rays start at the camera position.
        ray.origin = camera.position;

        // Map normalized pixel coordinates into the camera's coordinate system.
        ray.direction = normalize(uv.x * camera.right +
                                  uv.y * camera.up +
                                  camera.forward);

        // Don't limit the intersection distance.
        ray.max_distance = INFINITY;
        
        float time = halton(offset + frameData.frameIndex, 2);
        
        // Scale the time to a smaller window to avoid over-blurring. When rendering multiple
        // frames, this is based on framerate.
        time = 0.5f + (time - 0.5f) * 0.2f;

        // Start with a fully white color. The kernel scales the light each time the
        // ray bounces off of a surface, based on how much of each light component
        // the surface absorbs.
        float3 color = float3(1.0f, 1.0f, 1.0f);

        float3 accumulatedColor = float3(0.0f, 0.0f, 0.0f);

        // Create an intersector to test for intersection between the ray and the geometry in the scene.
        intersectorType i;
        
        // Provide some hints to Metal for better performance.
        i.assume_geometry_type(geometry_type::triangle);
        i.force_opacity(forced_opacity::opaque);

        typename intersectorType::result_type intersection;

        // Simulate up to three ray bounces.  Each bounce propagates light backward along the
        // ray's path toward the camera.
        for (int bounce = 0; bounce < 3; bounce++)
        {
            // Get the closest intersection, not the first intersection. This is the default, but
            // the sample adjusts this property below when it casts shadow rays.
            i.accept_any_intersection(false);

            // Check for intersection between the ray and the acceleration structure. If the sample
            // isn't using intersection functions, it doesn't need to include one.
            intersection = i.intersect(ray, accelerationStructure, bounce == 0 ? RAY_MASK_PRIMARY :  RAY_MASK_SECONDARY, time);

            // Stop if the ray doesn't hit anything and bounces out of the scene.
            if (intersection.type == intersection_type::none)
                break;
            
            unsigned int instanceIndex = intersection.instance_id;

            // Look up the mask for this instance, which indicates what type of geometry the ray hits.
            unsigned int mask = instances[instanceIndex].mask;

            // If the ray hits a light source, set the color to white and stop immediately.
            if (mask == GEOMETRY_MASK_LIGHT)
            {
                accumulatedColor = float3(1.0f, 1.0f, 1.0f);
                break;
            }

            // The ray hits something. Look up the transformation matrix for this instance.
            
            // Compute the intersection point in world space.
            float3 worldSpaceIntersectionPoint = ray.origin + ray.direction * intersection.distance;

            unsigned primitiveIndex = intersection.primitive_id;
            unsigned int geometryIndex = instances[instanceIndex].accelerationStructureIndex;
            float2 barycentric_coords = intersection.triangle_barycentric_coord;

            float3 objectSpaceSurfaceNormal = 0.0f;
            float3 surfaceColor = 0.0f;

            // The intersector automatically interpolates this matrix if the intersected object has instance_motion.
            float4x3 objectToWorldSpaceTransform = intersection.object_to_world_transform;
            
            // Because the ray hits a triangle, look up the corresponding geometry's normal and color buffers.
            device MeshResources & meshResources = resources[geometryIndex];

            // If the intersected object doesn't have primitive_motion, the kernel
            // uses color and normal values without modifications. The primitive
            // motion keyframe count is always one when primitive_motion is in a disabled state.
            if(meshResources.primitiveMotionKeyframeCount == 1)
            {
                device KeyframeResources & keyframeResources = meshResources.keyframes[0];

                // Interpolate the vertex normal at the intersection point.
                objectSpaceSurfaceNormal = normalize(interpolateVertexAttribute(keyframeResources.vertexNormals, primitiveIndex, barycentric_coords));

                // Interpolate the vertex color at the intersection point.
                surfaceColor = interpolateVertexAttribute(keyframeResources.vertexColors, primitiveIndex, barycentric_coords);
            }
            else
            {
                // The kernel interpolates normal and color values because the
                // intersected object has primitive_motion.
                float scaledTime = time * meshResources.primitiveMotionKeyframeCount;

                // Compute the indices of the keyframes before and after the random time the app chooses
                // for this ray.  This computation is simpler because the animation only ranges
                // from time=0 to time=1.  The min() ensures that the keyframe index doesn't go out
                // of bounds for time=1.
                unsigned int keyframe0Index = min((unsigned int)scaledTime, meshResources.primitiveMotionKeyframeCount - 1);
                unsigned int keyframe1Index = min(keyframe0Index + 1, meshResources.primitiveMotionKeyframeCount - 1);

                // Compute how much to blend between the two keyframes.
                float weight = saturate(scaledTime - keyframe0Index);

                // Look up the keyframe resources for the two keyframes.
                device KeyframeResources & keyframe0Resources = meshResources.keyframes[keyframe0Index];
                device KeyframeResources & keyframe1Resources = meshResources.keyframes[keyframe1Index];

                // Interpolate the vertex normal for each keyframe at the intersection point.
                float3 objectSpaceSurfaceNormal0 = normalize(interpolateVertexAttribute(keyframe0Resources.vertexNormals, primitiveIndex, barycentric_coords));
                float3 objectSpaceSurfaceNormal1 = normalize(interpolateVertexAttribute(keyframe1Resources.vertexNormals, primitiveIndex, barycentric_coords));

                // Blend the two vertex normals to get the vertex normal for the current time.
                objectSpaceSurfaceNormal = normalize(mix(objectSpaceSurfaceNormal0, objectSpaceSurfaceNormal1, weight));

                // Interpolate the vertex color for each keyframe at the intersection point.
                float3 color0 = interpolateVertexAttribute(keyframe0Resources.vertexColors, primitiveIndex, barycentric_coords);
                float3 color1 = interpolateVertexAttribute(keyframe1Resources.vertexColors, primitiveIndex, barycentric_coords);

                // Blend the two vertex colors to get the vertex color for the current time.
                surfaceColor = mix(color0, color1, weight);
            }

            // Transform the normal from object to world space.
            float3 worldSpaceSurfaceNormal = transformDirection(objectSpaceSurfaceNormal, objectToWorldSpaceTransform);
            
            // Choose a random light source to sample.
            float lightSample = halton(offset + frameData.frameIndex, 3 + bounce * 5 + 0);
            unsigned int lightIndex = min((unsigned int)(lightSample * frameData.lightCount), frameData.lightCount - 1);

            // Choose a random point to sample on the light source.
            float2 r = float2(halton(offset + frameData.frameIndex, 3 + bounce * 5 + 1),
                              halton(offset + frameData.frameIndex, 3 + bounce * 5 + 2));

            float3 worldSpaceLightDirection;
            float3 lightColor;
            float lightDistance;

            // Sample the lighting between the intersection point and the point on the area light.
            sampleAreaLight(areaLights[lightIndex], r, worldSpaceIntersectionPoint, worldSpaceLightDirection,
                            lightColor, lightDistance);

            // Scale the light color by the cosine of the angle between the light direction and
            // surface normal.
            lightColor *= saturate(dot(worldSpaceSurfaceNormal, worldSpaceLightDirection));

            // Scale the light color by the number of lights to compensate for the fact that
            // the sample only samples one light source at random.
            lightColor *= frameData.lightCount;

            // Scale the ray color by the color of the surface.  This simulates ths surface
            // absorbing the light.
            color *= surfaceColor;

            // Compute the shadow ray. The shadow ray checks whether the sample position
            // on the light source is visible from the current intersection point.
            // If it is, the kernel adds lighting to the output image.
            struct ray shadowRay;

            // Add a small offset to the intersection point to avoid intersecting the same
            // triangle again.
            shadowRay.origin = worldSpaceIntersectionPoint + worldSpaceSurfaceNormal * 1e-3f;

            // Travel toward the light source.
            shadowRay.direction = worldSpaceLightDirection;

            // Don't overshoot the light source.
            shadowRay.max_distance = lightDistance - 1e-3f;

            // The shadow rays check only whether there is an object between the intersection point
            // and the light source.  Tell Metal to return after finding any intersection.
            i.accept_any_intersection(true);

            intersection = i.intersect(shadowRay, accelerationStructure, RAY_MASK_SHADOW, time);
            
            // If there is no intersection, the light source is visible from the original
            // intersection point. Add the light's contribution to the image.
            if (intersection.type == intersection_type::none)
                accumulatedColor += lightColor * color;

            // Choose a random direction to continue the path of the ray.  This causes
            // light to bounce between surfaces.  The sample can apply a fair bit of math
            // to compute the fraction of light that the current intersection point reflects to the
            // previous point from the next point.  However, by choosing a random direction with
            // probability proportional to the cosine (dot product) of the angle between the
            // sample direction and surface normal, the math entirely cancels out except for
            // multiplying by the surface color.  This sampling strategy also reduces the amount
            // of noise in the output image.
            r = float2(halton(offset + frameData.frameIndex, 3 + bounce * 5 + 3),
                       halton(offset + frameData.frameIndex, 3 + bounce * 5 + 4));

            float3 worldSpaceSampleDirection = sampleCosineWeightedHemisphere(r);
            worldSpaceSampleDirection = alignHemisphereWithNormal(worldSpaceSampleDirection, worldSpaceSurfaceNormal);

            ray.origin = worldSpaceIntersectionPoint + worldSpaceSurfaceNormal * 1e-3f;
            ray.direction = worldSpaceSampleDirection;
        }

        // Average this frame's sample with all of the previous frame's samples.
        if (frameData.frameIndex > 0)
        {
            float3 prevColor = prevTex.read(tid).xyz;
            prevColor *= frameData.frameIndex;

            accumulatedColor += prevColor;
            accumulatedColor /= (frameData.frameIndex + 1);
        }

        dstTex.write(float4(accumulatedColor, 1.0f), tid);
    }
}

template
[[host_name("raytracingInstanceAndPrimitiveMotionKernel")]]
kernel void raytracingKernel<acceleration_structure<instancing, instance_motion, primitive_motion>, intersector<triangle_data, instancing, world_space_data, instance_motion, primitive_motion>>(uint2 tid [[thread_position_in_grid]],
                                                                                                                                                                                                 constant FrameData & frameData,
                                                                                                                                                                                                 texture2d<unsigned int> randomTex,
                                                                                                                                                                                                 texture2d<float> prevTex,
                                                                                                                                                                                                 texture2d<float, access::write> dstTex,
                                                                                                                                                                                                 device MeshResources *resources,
                                                                                                                                                                                                 device MTLAccelerationStructureMotionInstanceDescriptor *instances,
                                                                                                                                                                                                 device AreaLight *areaLights,
                                                                                                                                                                                                 acceleration_structure<instancing, instance_motion, primitive_motion> accelerationStructure);


template
[[host_name("raytracingInstanceMotionKernel")]]
kernel void raytracingKernel<acceleration_structure<instancing, instance_motion>, intersector<triangle_data, instancing, world_space_data, instance_motion>>(uint2 tid [[thread_position_in_grid]],
                                                                                                                                                             constant FrameData & frameData,
                                                                                                                                                             texture2d<unsigned int> randomTex,
                                                                                                                                                             texture2d<float> prevTex,
                                                                                                                                                             texture2d<float, access::write> dstTex,
                                                                                                                                                             device MeshResources *resources,
                                                                                                                                                             device MTLAccelerationStructureMotionInstanceDescriptor *instances,
                                                                                                                                                             device AreaLight *areaLights,
                                                                                                                                                             acceleration_structure<instancing, instance_motion> accelerationStructure);

// The quad for filling the screen in normalized device coordinates.
constant float2 quadVertices[] =
{
    float2(-1, -1),
    float2(-1,  1),
    float2( 1,  1),
    float2(-1, -1),
    float2( 1,  1),
    float2( 1, -1)
};

struct CopyVertexOut
{
    float4 position [[position]];
    float2 uv;
};

// A simple vertex shader that passes through NDC quad positions.
vertex CopyVertexOut copyVertex(unsigned short vid [[vertex_id]])
{
    float2 position = quadVertices[vid];

    CopyVertexOut out;

    out.position = float4(position, 0, 1);
    out.uv = position * 0.5f + 0.5f;

    return out;
}

// A simple fragment shader that copies a texture and applies a simple tonemapping function.
fragment float4 copyFragment(CopyVertexOut in [[stage_in]],
                             texture2d<float> tex)
{
    constexpr sampler sam(min_filter::nearest, mag_filter::nearest, mip_filter::none);

    float3 color = tex.sample(sam, in.uv).xyz;

    // Apply a very simple tonemapping function to reduce the dynamic range of the
    // input image into a range that the screen can display.
    color = color / (1.0f + color);

    return float4(color, 1.0f);
}
