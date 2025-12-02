/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app delegate that sets up and starts the virtual machine.
*/

#import "AppDelegate.h"

#import "Error.h"
#import "MacOSVirtualMachineConfigurationHelper.h"
#import "MacOSVirtualMachineDelegate.h"
#import "Path.h"

#import <Virtualization/Virtualization.h>

@interface AppDelegate ()

@property (weak) IBOutlet VZVirtualMachineView *virtualMachineView;

@property (strong) IBOutlet NSWindow *window;

@end

@implementation AppDelegate {
    VZVirtualMachine *_virtualMachine;
    MacOSVirtualMachineDelegate *_delegate;
}

#ifdef __arm64__

// MARK: Create the Mac platform configuration.

- (VZMacPlatformConfiguration *)createMacPlatformConfiguration
{
    VZMacPlatformConfiguration *macPlatformConfiguration = [[VZMacPlatformConfiguration alloc] init];
    VZMacAuxiliaryStorage *auxiliaryStorage = [[VZMacAuxiliaryStorage alloc] initWithContentsOfURL:getAuxiliaryStorageURL()];
    macPlatformConfiguration.auxiliaryStorage = auxiliaryStorage;

    if (![[NSFileManager defaultManager] fileExistsAtPath:getVMBundlePath()]) {
        abortWithErrorMessage([NSString stringWithFormat:@"Missing Virtual Machine Bundle at %@. Run InstallationTool first to create it.", getVMBundlePath()]);
    }

    // Retrieve the hardware model and save this value to disk during installation.
    NSData *hardwareModelData = [[NSData alloc] initWithContentsOfURL:getHardwareModelURL()];
    if (!hardwareModelData) {
        abortWithErrorMessage(@"Failed to retrieve hardware model data.");
    }

    VZMacHardwareModel *hardwareModel = [[VZMacHardwareModel alloc] initWithDataRepresentation:hardwareModelData];
    if (!hardwareModel) {
        abortWithErrorMessage(@"Failed to create hardware model.");
    }

    if (!hardwareModel.supported) {
        abortWithErrorMessage(@"The hardware model isn't supported on the current host");
    }
    macPlatformConfiguration.hardwareModel = hardwareModel;

    // Retrieve the machine identifier and save this value to disk
    // during installation.
    NSData *machineIdentifierData = [[NSData alloc] initWithContentsOfURL:getMachineIdentifierURL()];
    if (!machineIdentifierData) {
        abortWithErrorMessage(@"Failed to retrieve machine identifier data.");
    }

    VZMacMachineIdentifier *machineIdentifier = [[VZMacMachineIdentifier alloc] initWithDataRepresentation:machineIdentifierData];
    if (!machineIdentifier) {
        abortWithErrorMessage(@"Failed to create machine identifier.");
    }
    macPlatformConfiguration.machineIdentifier = machineIdentifier;

    return macPlatformConfiguration;
}

// MARK: Create the virtual machine configuration and instantiate the virtual machine.

- (void)createVirtualMachine
{
    VZVirtualMachineConfiguration *configuration = [VZVirtualMachineConfiguration new];

    configuration.platform = [self createMacPlatformConfiguration];
    configuration.CPUCount = [MacOSVirtualMachineConfigurationHelper computeCPUCount];
    configuration.memorySize = [MacOSVirtualMachineConfigurationHelper computeMemorySize];

    configuration.bootLoader = [MacOSVirtualMachineConfigurationHelper createBootLoader];

    configuration.audioDevices = @[ [MacOSVirtualMachineConfigurationHelper createSoundDeviceConfiguration] ];
    configuration.graphicsDevices = @[ [MacOSVirtualMachineConfigurationHelper createGraphicsDeviceConfiguration] ];
    configuration.networkDevices = @[ [MacOSVirtualMachineConfigurationHelper createNetworkDeviceConfiguration] ];
    configuration.storageDevices = @[ [MacOSVirtualMachineConfigurationHelper createBlockDeviceConfiguration] ];

    configuration.pointingDevices = @[ [MacOSVirtualMachineConfigurationHelper createPointingDeviceConfiguration] ];
    configuration.keyboards = @[ [MacOSVirtualMachineConfigurationHelper createKeyboardConfiguration] ];
    
    BOOL isValidConfiguration = [configuration validateWithError:nil];
    if (!isValidConfiguration) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Invalid configuration" userInfo:nil];
    }
    
    if (@available(macOS 14.0, *)) {
        BOOL supportsSaveRestore = [configuration validateSaveRestoreSupportWithError:nil];
        if (!supportsSaveRestore) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Invalid configuration" userInfo:nil];
        }
    }

    _virtualMachine = [[VZVirtualMachine alloc] initWithConfiguration:configuration];
}

// MARK: Start or restore the virtual machine.

- (void)startVirtualMachine
{
    [_virtualMachine startWithCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            abortWithErrorMessage([NSString stringWithFormat:@"%@%@", @"Virtual machine failed to start with ", error.localizedDescription]);
        }
    }];
}

- (void)resumeVirtualMachine
{
    [_virtualMachine resumeWithCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            abortWithErrorMessage([NSString stringWithFormat:@"%@%@", @"Virtual machine failed to resume with ", error.localizedDescription]);
        }
    }];
}

- (void)restoreVirtualMachine API_AVAILABLE(macosx(14.0));
{
    [_virtualMachine restoreMachineStateFromURL:getSaveFileURL() completionHandler:^(NSError * _Nullable error) {
        // Remove the saved file. Whether success or failure, the state no longer matches the VM's disk.
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtURL:getSaveFileURL() error:nil];

        if (!error) {
            [self resumeVirtualMachine];
        } else {
            [self startVirtualMachine];
        }
    }];
}
#endif

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
#ifdef __arm64__
    dispatch_async(dispatch_get_main_queue(), ^{
        [self createVirtualMachine];

        self->_delegate = [MacOSVirtualMachineDelegate new];
        self->_virtualMachine.delegate = self->_delegate;
        self->_virtualMachineView.virtualMachine = self->_virtualMachine;
        self->_virtualMachineView.capturesSystemKeys = YES;

        if (@available(macOS 14.0, *)) {
            // Configure the app to automatically respond to changes in the display size.
            self->_virtualMachineView.automaticallyReconfiguresDisplay = YES;
        }

        if (@available(macOS 14.0, *)) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:getSaveFileURL().path]) {
                [self restoreVirtualMachine];
            } else {
                [self startVirtualMachine];
            }
        } else {
            [self startVirtualMachine];
        }
    });
#endif
}

// MARK: Save the virtual machine when the app exits.

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}

#ifdef __arm64__
- (void)saveVirtualMachine:(void (^)(void))completionHandler API_AVAILABLE(macosx(14.0));
{
    [_virtualMachine saveMachineStateToURL:getSaveFileURL() completionHandler:^(NSError * _Nullable error) {
        if (error) {
            abortWithErrorMessage([NSString stringWithFormat:@"%@%@", @"Virtual machine failed to save with ", error.localizedDescription]);
        }
        
        completionHandler();
    }];
}

- (void)pauseAndSaveVirtualMachine:(void (^)(void))completionHandler API_AVAILABLE(macosx(14.0));
{
    [_virtualMachine pauseWithCompletionHandler:^(NSError * _Nullable error) {
        if (error) {
            abortWithErrorMessage([NSString stringWithFormat:@"%@%@", @"Virtual machine failed to pause with ", error.localizedDescription]);
        }

        [self saveVirtualMachine:completionHandler];
    }];
}
#endif

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender;
{
#ifdef __arm64__
    if (@available(macOS 14.0, *)) {
        if (_virtualMachine.state == VZVirtualMachineStateRunning) {
            [self pauseAndSaveVirtualMachine:^(void) {
                [sender replyToApplicationShouldTerminate:YES];
            }];
            
            return NSTerminateLater;
        }
    }
#endif

    return NSTerminateNow;
}

@end
