/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines the structure and initial values for the model instances.
*/

#include <simd/simd.h>
#include <Foundation/Foundation.h>

/// The maximum number of objects in the world (not counting the skybox).
///
/// You can add a new model instance with the following steps:
/// 1. Increase `kMaxModelInstances` by `1`.
/// 2. Create a mesh in the `AAPLRenderer::loadAssets` method.
/// 3. Reference your mesh and set its properties by modifying
/// the `configureModelInstances` function (in `AAPLModelInstance.m`).
#define kMaxModelInstances 4

/// A C-structure that stores the details of an instance of a model for a scene.
typedef struct ModelInstance
{
    /// The mesh index that corresponds to the model instance.
    uint32_t meshIndex;

    /// The model instance's position in the world.
    vector_float3 position;

    /// The model instance's vertical rotation about the y-axis, in radians.
    float rotation;
} ModelInstance;

/// Initializes the model instances from hard-coded values.
/// - Parameters:
///   - modelInstances: A pointer to a C-array of model instances.
///   - count: The number of model instances in the array.
void configureModelInstances(ModelInstance *modelInstances, uint32_t count);
