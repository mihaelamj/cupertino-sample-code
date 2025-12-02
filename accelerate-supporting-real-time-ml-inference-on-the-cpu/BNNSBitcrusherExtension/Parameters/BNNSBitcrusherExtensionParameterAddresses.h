/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The BNNS bitcrusher parameter address file.
*/

#pragma once

#include <AudioToolbox/AUParameters.h>

#ifdef __cplusplus
namespace BNNSBitcrusherExtensionParameterAddress {
#endif

typedef NS_ENUM(AUParameterAddress, BNNSBitcrusherExtensionParameterAddress) {
    resolution = 0,
    saturationGain = 1,
    mix = 2
};

#ifdef __cplusplus
}
#endif
