/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The shader code for the custom operation.
*/

#pragma once

// Defines the Metal soft shrink custom kernel.
static char *CUSTOM_KERNEL = R"MPS_SOFTSHRINK(
#include <metal_stdlib>
using namespace metal;

// SoftShrinkage(x) = x - lambda, if x > lambda
//                    x + lambda, if x < -lambda
//                    0,          otherwise
template<typename T>
kernel void softshrink_kernel(constant T*     input  [[buffer(0)]],
                              device   T*     output [[buffer(1)]],
                              constant float& lambda [[buffer(2)]],
                              uint index [[thread_position_in_grid]]) {
    output[index] = input[index] >  lambda ? input[index] - lambda :
                    input[index] < -lambda ? input[index] + lambda : 0;
}

template
[[host_name("softshrink_kernel_half")]]
kernel void softshrink_kernel<half>(constant half*  input  [[buffer(0)]],
                                    device   half*  output [[buffer(1)]],
                                    constant float& lambda [[buffer(2)]],
                                    uint index [[thread_position_in_grid]]);

template
[[host_name("softshrink_kernel_float")]]
kernel void softshrink_kernel<float>(constant float*  input  [[buffer(0)]],
                                     device   float*  output [[buffer(1)]],
                                     constant float& lambda  [[buffer(2)]],
                                     uint index [[thread_position_in_grid]]);
)MPS_SOFTSHRINK";
