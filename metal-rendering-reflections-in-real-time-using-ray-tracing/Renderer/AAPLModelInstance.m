/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines the method for initializing model instances.
*/

#include "AAPLModelInstance.h"

#include <stdio.h>
#include <assert.h>

void configureModelInstances(ModelInstance *modelInstances, uint32_t count)
{
    switch (count) {
        case 4:
            modelInstances[3].meshIndex = 2;
            modelInstances[3].position = (vector_float3){ 0.0f, -5.0f, -0.0f };
            modelInstances[3].rotation = 0.0f;

            // Intentionally fall through to the remaining cases (don't include `break;`).
        case 3:
            modelInstances[2].meshIndex = 1;
            modelInstances[2].position = (vector_float3){ -5.0f, 2.75f, -55.0f };
            modelInstances[2].rotation = 0.0f;
            
            // Intentionally fall through to the remaining cases (don't include `break;`).
        case 2:
            modelInstances[1].meshIndex = 0;
            modelInstances[1].position = (vector_float3){ -13.0f, -5.0f, -20.0f };
            modelInstances[1].rotation = 235 * M_PI / 180.0f;

            // Intentionally fall through to the last case (don't include `break;`).
        case 1:
            modelInstances[0].meshIndex = 0;
            modelInstances[0].position = (vector_float3){ 20.0f, -5.0f, -40.0f };
            modelInstances[0].rotation = 135 * M_PI / 180.0f;
            break;

        default:
            printf("This method expects a count in the range: [1, %lu].",
                   (unsigned long)kMaxModelInstances);

            assert(0 < count && count <= kMaxModelInstances);
    }
}
