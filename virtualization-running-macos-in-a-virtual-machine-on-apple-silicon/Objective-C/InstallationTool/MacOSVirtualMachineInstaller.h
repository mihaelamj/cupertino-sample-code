/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The helper class to install a macOS virtual machine.
*/

#ifndef MacOSVirtualMachineInstaller_h
#define MacOSVirtualMachineInstaller_h

#import <Foundation/Foundation.h>

#ifdef __arm64__

@interface MacOSVirtualMachineInstaller : NSObject

- (void)setUpVirtualMachineArtifacts;

- (void)installMacOS:(NSURL *)ipswURL;

@end

#endif /* __arm64__ */
#endif /* MacOSVirtualMachineInstaller_h */
