/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The helper that creates various configuration objects exposed in the `VZVirtualMachineConfiguration`.
*/

#ifndef MacOSVirtualMachineConfigurationHelper_h
#define MacOSVirtualMachineConfigurationHelper_h

#import <Virtualization/Virtualization.h>

#ifdef __arm64__

@interface MacOSVirtualMachineConfigurationHelper : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;

+ (NSUInteger)computeCPUCount;

+ (uint64_t)computeMemorySize;

+ (VZMacOSBootLoader *)createBootLoader;

+ (VZVirtioBlockDeviceConfiguration *)createBlockDeviceConfiguration;
+ (VZMacGraphicsDeviceConfiguration *)createGraphicsDeviceConfiguration;
+ (VZVirtioNetworkDeviceConfiguration *)createNetworkDeviceConfiguration;
+ (VZVirtioSoundDeviceConfiguration *)createSoundDeviceConfiguration;

+ (VZPointingDeviceConfiguration *)createPointingDeviceConfiguration;
+ (VZKeyboardConfiguration *)createKeyboardConfiguration;

@end

#endif /* __arm64__ */
#endif /* MacOSVirtualMachineConfigurationHelper_h */
