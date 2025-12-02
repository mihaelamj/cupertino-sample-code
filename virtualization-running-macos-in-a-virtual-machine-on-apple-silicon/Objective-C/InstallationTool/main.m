/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry for `InstallationTool`.
*/

#import "Error.h"
#import "MacOSRestoreImage.h"
#import "MacOSVirtualMachineInstaller.h"
#import "Path.h"

#import <Foundation/Foundation.h>

int main(int argc, const char * argv[])
{
#ifdef __arm64__
    @autoreleasepool {
        MacOSVirtualMachineInstaller *installer = [MacOSVirtualMachineInstaller new];

        if (argc == 2) {
            NSString *ipswPath = [NSString stringWithUTF8String:argv[1]];

            NSURL *ipswURL = [[NSURL alloc] initFileURLWithPath:ipswPath];
            if (!ipswURL.isFileURL) {
                abortWithErrorMessage(@"The provided IPSW path is not a valid file URL.");
            }

            [installer setUpVirtualMachineArtifacts];
            [installer installMacOS:ipswURL];

            dispatch_main();
        } else if (argc == 1) {
            [installer setUpVirtualMachineArtifacts];

            MacOSRestoreImage *restoreImage = [MacOSRestoreImage new];
            [restoreImage download:^{
                // Install from the restore image that you downloaded.
                [installer installMacOS:getRestoreImageURL()];
            }];

            dispatch_main();
        } else {
            NSLog(@"Invalid argument. Please either provide the path to an IPSW file, or run this tool without any argument.");
            exit(-1);
        }
    }
#else
    NSLog(@"This tool can only be run on Apple Silicon Macs.");
    exit(-1);
#endif
}
