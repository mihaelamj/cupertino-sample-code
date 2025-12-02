/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of user functions compiled as overrides for a dynamic library.
*/

#include <metal_stdlib>

using namespace metal;

#pragma mark Linked Functions

// These functions get compiled and built into a dynamic library when the user
// changes the visualization mode to `Debug`.
namespace AAPLUserDylib
{
    float4 calculateColorInside(int iteration, float distance)
    {
        return float4(1.0, 0.0, 0.0, 1.0);
    }

    float4 calculateColorEscaped(int iteration, float distance)
    {
        return float4(1.0, 1.0, 0.0, 1.0);
    }
}
