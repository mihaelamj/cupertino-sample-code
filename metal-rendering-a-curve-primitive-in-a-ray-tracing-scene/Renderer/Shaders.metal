/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Metal shaders that this sample uses.
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
// base. The Halton sequence is a low-discrepancy sequence: the values appear
// random, but are more evenly distributed than a purely random sequence. Each random
// value the system uses to render the image uses a different independent dimension, `d`,
// and each sample (frame) uses a different index `i`. To decorrelate each pixel,
// you can apply a random offset to `i`.
float halton(unsigned int i, unsigned int d) {
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

// Uses the inversion method to map two uniformly random numbers to a 3D
// unit hemisphere, where the probability of a given sample is proportional to the cosine
// of the angle between the sample direction and the "up" direction (0, 1, 0).
inline float3 sampleCosineWeightedHemisphere(float2 u) {
    float phi = 2.0f * M_PI_F * u.x;
    
    float cos_phi;
    float sin_phi = sincos(phi, cos_phi);
    
    float cos_theta = sqrt(u.y);
    float sin_theta = sqrt(1.0f - cos_theta * cos_theta);
    
    return float3(sin_theta * cos_phi, cos_theta, sin_theta * sin_phi);
}

// Get sky color.
inline float3 interpolateSkyColor(float3 ray) {
    float t = mix(ray.y, 1.0f, 0.5f);
    return mix(float3(1.0f, 1.0f, 1.0f), float3(0.45f, 0.65f, 1.0f), t);
}

// Aligns a direction on the unit hemisphere such that the hemisphere's "up" direction
// (0, 1, 0) maps to the given surface normal direction.
inline float3 alignHemisphereWithNormal(float3 sample, float3 normal) {
    // Set the "up" vector to the normal
    float3 up = normal;
    
    // Find an arbitrary direction perpendicular to the normal, which becomes the
    // "right" vector.
    float3 right = normalize(cross(normal, float3(0.0072f, 1.0f, 0.0034f)));
    
    // Find a third vector perpendicular to the previous two, which becomes the
    // "forward" vector.
    float3 forward = cross(right, up);
    
    // Map the direction on the unit hemisphere to the coordinate system aligned
    // with the normal.
    return sample.x * right + sample.y * up + sample.z * forward;
}

/*
 The custom curves intersection function. The [[intersection]] keyword marks this as an intersection
 function. The [[curve]] keyword means that this intersection function handles intersecting rays
 with curve primitives.
 
 The [[curve_data]] and [[instancing]] keywords indicate that the intersector that calls this
 intersection function returns a curve parameter value of type float. This parameter is the value
 to pass to the curve basis functions to reconstruct the position of the
 intersection along the curve segment. Note that this value is generally not the distance along
 the curve, nor does it vary linearly with distance along the curve. It does, however, increase
 monotonically with distance along the curve. It's up to the app to compute a linear
 (that is, an arc-length) parameterization of the curve if the app requires one.
 Also note that the position that the basis functions return isn't the same as the actual intersection
 point (that is, origin + direction * distance) because the curve has a nonzero radius.
 
 The combination of these keywords needs to match between the intersection functions, intersection function table,
 intersector, and intersection result to ensure that Metal propagates data correctly between stages.
 
 The arguments to the intersection function contain information about the ray, primitive to be
 tested, and so on. The ray intersector provides this data when it calls the intersection function.
 Metal provides other built-in arguments, but this sample doesn't use them.
 */
[[intersection (triangle, triangle_data, curve_data, instancing)]]
bool triangleIntersectionFunction(// Ray parameters passed to the ray intersector.
                                  float3 origin               [[origin]],
                                  float3 direction            [[direction]],
                                  float distance              [[distance]],
                                  // Information about the primitive.
                                  uint primitiveId            [[primitive_id]],
                                  float2 uv                   [[barycentric_coord]],
                                  ray_data float3& normal     [[payload]],
                                  // Custom resources bound to the intersection function table.
                                  constant float3 *vertexNormals   [[buffer(2)]],
                                  constant uint16_t *vertexIndices [[buffer(3)]]
                                  )
{
    // Look up the corresponding geometry's normal.
    float3 t0 = vertexNormals[vertexIndices[primitiveId * 3 + 0]];
    float3 t1 = vertexNormals[vertexIndices[primitiveId * 3 + 1]];
    float3 t2 = vertexNormals[vertexIndices[primitiveId * 3 + 2]];
    
    // Compute the sum of the vertex attributes weighted by the barycentric coordinates.
    // The barycentric coordinates sum to one.
    normal = (1.0f - uv.x - uv.y) * t0 + uv.x * t1 + uv.y * t2;
    return true;
}

[[intersection (curve, triangle_data, curve_data, instancing)]]
bool catmullRomCurveIntersectionFunction(// Ray parameters passed to the ray intersector.
                                         float3 origin                    [[origin]],
                                         float3 direction                 [[direction]],
                                         float distance                   [[distance]],
                                         // Information about the primitive.
                                         uint segmentId                   [[primitive_id]],
                                         float t                          [[curve_parameter]],
                                         ray_data float3& normal          [[payload]],
                                         // Custom resources bound to the intersection function table.
                                         constant float3   *controlPoints [[buffer(0)]],
                                         constant uint16_t *indices       [[buffer(1)]]
                                         )
{
    // This function's purpose is to demonstrate the developer's ability to use
    // custom intersection functions for curves, but isn't required in this case.
    // It's recommended to make the computations outside custom intersection functions
    // to avoid unnecessary computations for the instances that the intersector filters out.
    
    // Find the intersection point.
    float3 localSpaceIntersectionPoint = origin + direction * distance;
    
    // Each curve segment is considered to be an individual primitive.
    // The index of the curve segment is represented by the primitive_id value.
    int idx = indices[segmentId];
    float3 cp0 = controlPoints[idx + 0];
    float3 cp1 = controlPoints[idx + 1];
    float3 cp2 = controlPoints[idx + 2];
    float3 cp3 = controlPoints[idx + 3];
    
    // If t == 0 or t == 1, then the point is on a curve's cap.
    // Note that similar to triangle_data, curve_parameter is only available when the curve_data tag is specified.
    if (t == 0.0f || t == 1.0f)
    {
        // Use the Metal library Catmull-Rom derivative function to evaluate the curve's derivative at point t.
        normal = catmull_rom_derivative(t, cp0, cp1, cp2, cp3);
        // Use the opposite direction to make the normal's direction be outside the curve.
        normal *= (t == 0.0f) ? -1 : 1;
    }
    else
    {
        // Use the Metal library Catmull-Rom basis function to evaluate the curve at point t.
        float3 pointOnCurve = catmull_rom(t, cp0, cp1, cp2, cp3);
        // Calculate the normal to the curve.
        // Note that the position that the basis functions return isn't the same
        // as the actual intersection point computed above because the curve has a nonzero radius.
        normal = normalize(localSpaceIntersectionPoint - pointOnCurve);
    }
    return true;
}

// The main ray-tracing kernel.
kernel void raytracingKernel(
                             uint2                                                  tid                       [[thread_position_in_grid]],
                             constant Uniforms &                                    uniforms                  [[buffer(0)]],
                             texture2d<unsigned int>                                randomTex                 [[texture(0)]],
                             texture2d<float>                                       prevTex                   [[texture(1)]],
                             texture2d<float, access::write>                        dstTex                    [[texture(2)]],
                             constant MTLAccelerationStructureInstanceDescriptor   *instances                 [[buffer(1)]],
                             acceleration_structure<instancing>                     accelerationStructure     [[buffer(2)]],
                             intersection_function_table<curve_data, triangle_data, instancing>    intersectionFunctionTable [[buffer(3)]],
                             constant matrix_float4x4                              *transform                 [[buffer(4)]]
                             )
{
    // The sample aligns the thread count to the threadgroup size, which means the thread count
    // may be different than the bounds of the texture. Test to make sure this thread
    // is referencing a pixel within the bounds of the texture.
    if (tid.x >= uniforms.width && tid.y >= uniforms.height) {
        return;
    }
    
    ray ray;
    
    // The pixel coordinates for this thread.
    float2 pixel = (float2)tid;
    
    // Apply a random offset to the random number index to decorrelate pixels.
    unsigned int offset = randomTex.read(tid).x;
    
    // Add a random offset to the pixel coordinates for antialiasing.
    float2 r = float2(halton(offset + uniforms.frameIndex, 0),
                      halton(offset + uniforms.frameIndex, 1));
    
    pixel += r;
    
    // Map the pixel coordinates to -1..1.
    float2 uv = (float2)pixel / float2(uniforms.width, uniforms.height);
    uv = uv * 2.0f - 1.0f;
    
    constant Camera & camera = uniforms.camera;
    
    // Rays start at the camera position.
    ray.origin = camera.position;
    
    // Map the normalized pixel coordinates into the camera's coordinate system.
    ray.direction = normalize(uv.x * camera.right +
                              uv.y * camera.up +
                              camera.forward);
    
    // Don't limit the intersection distance.
    ray.max_distance = INFINITY;
    
    // Start with a fully white color. The kernel scales the light each time the
    // ray bounces off of a surface, based on how much of each light component
    // the surface absorbs.
    float3 accumulatedColor = float3(1.0f, 1.0f, 1.0f);
    float3 planeSurfaceColor = float3(0.5f, 0.5f, 0.5f);
    float3 curveSurfaceColor = float3(0.1f, 0.5f, 0.7f);
    
    // Create an intersector to test for intersection between the ray and the geometry in the scene.
    // Use curve_data, triangle_data, and instancing tags because the scene contains instances of
    // curve and triangle primitives.
    intersector<curve_data, triangle_data, instancing> i;
    typename intersector<curve_data, triangle_data, instancing>::result_type intersection;
    
    // Get the closest intersection, not the first intersection.
    i.accept_any_intersection(false);
    
    // Enabling curves has a cost even in cases where curves don't intersect.
    // The new default value of assume_geometry_type is geometry_type::bounding_box | geometry_type::triangle
    // (rather than geometry_type::all).
    // This means that for curves to intersect in an intersect call or an intersection query step,
    // the assume_geometry_type field needs to be explicitly set to a value, including geometry_type::curve.
    i.assume_geometry_type(geometry_type::curve | geometry_type::triangle);
    
    bool hitSky = false;
    int bounceCount = 3;
    
    for (int b = 0; b < bounceCount; ++b) {
        // Check for intersection between the ray and the acceleration structure.
        uint32_t m = 0xFF;
        float3 worldSpaceSurfaceNormal{0.0f, 0.0f, 0.0f};
        intersection = i.intersect(ray, accelerationStructure, m, intersectionFunctionTable, worldSpaceSurfaceNormal);
        
        // Stop if the ray didn't hit anything and bounced out of the scene.
        if (intersection.type == intersection_type::none) {
            float3 sky = interpolateSkyColor(ray.direction);
            accumulatedColor *= sky;
            hitSky = true;
            break;
        }
        else {
            // Calculate the intersection point on the ray and its normal.
            float3 worldSpaceIntersectionPoint = ray.origin + ray.direction * intersection.distance;
            if (intersection.type == intersection_type::curve) {
                accumulatedColor *= curveSurfaceColor;
            }
            else {
                accumulatedColor *= planeSurfaceColor;
            }
            
            // Transform the normal computed in the intersection function into the world space.
            uint instanceId = intersection.instance_id;
            matrix_float4x4 transformMatrix = transform[instanceId];
            worldSpaceSurfaceNormal = (transformMatrix * float4(worldSpaceSurfaceNormal, 0.0f)).xyz;
            
            // Choose a random point to sample on the hemisphere.
            float2 rp = float2(halton(offset + uniforms.frameIndex, 2),
                               halton(offset + uniforms.frameIndex, 3));
            
            // Sample from the cosine-weighted hemisphere and align with the normal.
            float3 worldSpaceLightDirection = sampleCosineWeightedHemisphere(rp);
            worldSpaceLightDirection = alignHemisphereWithNormal(worldSpaceLightDirection, worldSpaceSurfaceNormal);
            
            // Use this direction for the next bouncing iteration.
            ray.origin = worldSpaceIntersectionPoint;
            ray.direction = worldSpaceLightDirection;
            ray.min_distance = 1e-6;
        }
    }
    
    // If you hit the sky, use the accumulated color; otherwise, scale the sample contribution to zero.
    accumulatedColor = hitSky ? accumulatedColor : float3(0.0f, 0.0f, 0.0f);
    
    // Average this frame's sample with all of the previous frames.
    if (uniforms.frameIndex > 0) {
        float3 prevColor = prevTex.read(tid).xyz;
        prevColor *= uniforms.frameIndex;
        
        accumulatedColor += prevColor;
        accumulatedColor /= (uniforms.frameIndex + 1);
    }
    dstTex.write(float4(accumulatedColor, 1.0f), tid);
}

// The screen filling the quad in normalized device coordinates.
constant float2 quadVertices[] = {
    float2(-1, -1),
    float2(-1,  1),
    float2( 1,  1),
    float2(-1, -1),
    float2( 1,  1),
    float2( 1, -1)
};

struct CopyVertexOut {
    float4 position [[position]];
    float2 uv;
};

// A simple vertex shader that passes through NDC quad positions.
vertex CopyVertexOut copyVertex(unsigned short vid [[vertex_id]]) {
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
    
    // Apply a simple tonemapping function to reduce the dynamic range of the
    // input image into a range that the screen can display.
    color = color / (1.0f + color);
    
    return float4(color, 1.0f);
}

