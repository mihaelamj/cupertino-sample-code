/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The vDSP audio unit parameter address file.
*/

#pragma once

#include <AudioToolbox/AUParameters.h>

#ifdef __cplusplus
namespace vDSP_audio_unitExtensionParameterAddress {
#endif

typedef NS_ENUM(AUParameterAddress, vDSP_audio_unitExtensionParameterAddress) {
    frequency = 0,
    Q = 1,
    dbGain = 2
};

#ifdef __cplusplus
}
#endif
