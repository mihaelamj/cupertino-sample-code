/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header containing the structures and functions shared between the Metal shader files.
*/

#pragma once

struct FragData
{
    half4 resolvedColor [[color(0)]];
};

half3 tonemapByLuminance(half3 inColor);
