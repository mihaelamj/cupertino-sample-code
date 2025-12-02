/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of a user-generated dynamic library.
*/

#include <metal_stdlib>
#include "AAPLUserDylib.h"

using namespace metal;

#pragma mark Linked Functions

float4 AAPLUserDylib::calculateColorInside(int iteration, float distance)
{
    return float4(sin(distance), 0.0, cos(distance), 1.0);
}

float4 AAPLUserDylib::calculateColorEscaped(int iteration, float distance)
{
    return float4(iteration / 10.0, log(distance), iteration / 10.0, 1.0);
}
