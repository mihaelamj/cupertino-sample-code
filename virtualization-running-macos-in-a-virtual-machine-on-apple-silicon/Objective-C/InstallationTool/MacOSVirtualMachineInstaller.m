/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The helper class to install a macOS virtual machine.
*/

#ifdef __arm64__

#import "MacOSVirtualMachineInstaller.h"

#import "Error.h"
#import "MacOSVirtualMachineConfigurationHelper.h"
#import "MacOSVirtualMachineDelegate.h"
#import "Path.h"

#import <Foundation/Foundation.h>
#import <sys/stat.h>
#import <Virtualization/Virtualization.h>

@implementation MacOSVirtualMachineInstaller {
    VZVirtualMachine *_virtualMachine;
    MacOSVirtualMachineDelegate *_delegate;
}

// MARK: - Internal helper methods.

static void createVMBundle(void)
{
    NSError *error;
    BOOL bundleCreateResult = [[NSFileManager defaultManager] createDirectoryAtURL:getVMBundleURL()
                                                       withIntermediateDirectories:NO
                                                                        attributes:nil
                                                                             error:&error];
    if (!bundleCreateResult) {
        abortWithErrorMessage([error description]);
    }
}

// Virtualization framework supports two disk image formats:
// * RAW disk image: a file that has a 1-to-1 mapping between the offsets in the file and the offsets in the VM disk.
//   The logical size of a RAW disk image is the size of the disk itself.
//
//   In case the image file is stored on an APFS volume, the file will take less space
//   thanks to the sparse files feature of APFS.
//
// * ASIF disk image: A sparse image format. You can transfer ASIF files more efficiently between hosts or disks
//   as their sparsity doesn’t depend on the host’s filesystem capabilities.
//
// The framework supports ASIF since macOS 16.
static void createASIFDiskImage(void)
{
    NSError *error = nil;
    NSTask *task = [NSTask launchedTaskWithExecutableURL:[NSURL fileURLWithPath:@"/usr/sbin/diskutil"]
                                               arguments:@[@"image", @"create", @"blank", @"--fs", @"none", @"--format", @"ASIF", @"--size", @"128GiB", getDiskImageURL().path]
                                                   error:&error
                                      terminationHandler:nil];

    if (error != nil) {
        abortWithErrorMessage([NSString stringWithFormat:@"Failed to launch diskutil: %@", error]);
    }

    [task waitUntilExit];
    if (task.terminationStatus != 0) {
        abortWithErrorMessage(@"Disk image creation failed.");
    }
}

static void createRAWDiskImage(void)
{
    int fd = open([getDiskImageURL() fileSystemRepresentation], O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);
    if (fd == -1) {
        abortWithErrorMessage(@"Cannot create disk image.");
    }

    // 128 GB disk space.
    int result = ftruncate(fd, 128ull * 1024ull * 1024ull * 1024ull);
    if (result) {
        abortWithErrorMessage(@"ftruncate() failed.");
    }

    result = close(fd);
    if (result) {
        abortWithErrorMessage(@"Failed to close the disk image.");
    }
}

static void createDiskImage(void)
{
    if (@available(macOS 16.0, *)) {
        createASIFDiskImage();
    } else {
        createRAWDiskImage();
    }
}

// MARK: Create the Mac platform configuration.

- (VZMacPlatformConfiguration *)createMacPlatformConfiguration:(VZMacOSConfigurationRequirements *)macOSConfiguration
{
    VZMacPlatformConfiguration *macPlatformConfiguration = [[VZMacPlatformConfiguration alloc] init];

    NSError *error;
    VZMacAuxiliaryStorage *auxiliaryStorage = [[VZMacAuxiliaryStorage alloc] initCreatingStorageAtURL:getAuxiliaryStorageURL()
                                                                                        hardwareModel:macOSConfiguration.hardwareModel
                                                                                              options:VZMacAuxiliaryStorageInitializationOptionAllowOverwrite
                                                                                                error:&error];
    if (!auxiliaryStorage) {
        abortWithErrorMessage([NSString stringWithFormat:@"Failed to create auxiliary storage. %@", error.localizedDescription]);
    }

    macPlatformConfiguration.hardwareModel = macOSConfiguration.hardwareModel;
    macPlatformConfiguration.auxiliaryStorage = auxiliaryStorage;
    macPlatformConfiguration.machineIdentifier = [[VZMacMachineIdentifier alloc] init];

    // Store the hardware model and machine identifier to disk so that you can retrieve them for subsequent boots.
    [macPlatformConfiguration.hardwareModel.dataRepresentation writeToURL:getHardwareModelURL() atomically:YES];
    [macPlatformConfiguration.machineIdentifier.dataRepresentation writeToURL:getMachineIdentifierURL() atomically:YES];

    return macPlatformConfiguration;
}

// MARK: Create the virtual machine configuration and instantiate the virtual machine.

- (void)setupVirtualMachineWithMacOSConfigurationRequirements:(VZMacOSConfigurationRequirements *)macOSConfiguration
{
    VZVirtualMachineConfiguration *configuration = [VZVirtualMachineConfiguration new];

    configuration.platform = [self createMacPlatformConfiguration:macOSConfiguration];
    assert(configuration.platform);

    configuration.CPUCount = [MacOSVirtualMachineConfigurationHelper computeCPUCount];
    if (configuration.CPUCount < macOSConfiguration.minimumSupportedCPUCount) {
        abortWithErrorMessage(@"CPUCount is not supported by the macOS configuration.");
    }

    configuration.memorySize = [MacOSVirtualMachineConfigurationHelper computeMemorySize];
    if (configuration.memorySize < macOSConfiguration.minimumSupportedMemorySize) {
        abortWithErrorMessage(@"memorySize is not supported by the macOS configuration.");
    }

    // Create a 128 GB disk image.
    createDiskImage();

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

    self->_virtualMachine = [[VZVirtualMachine alloc] initWithConfiguration:configuration];
    self->_delegate = [MacOSVirtualMachineDelegate new];
    self->_virtualMachine.delegate = self->_delegate;
}

- (void)startInstallationWithRestoreImageFileURL:(NSURL *)restoreImageFileURL
{
    VZMacOSInstaller *installer = [[VZMacOSInstaller alloc] initWithVirtualMachine:self->_virtualMachine restoreImageURL:restoreImageFileURL];

    NSLog(@"Starting installation.");
    [installer installWithCompletionHandler:^(NSError *error) {
        if (error) {
            abortWithErrorMessage([NSString stringWithFormat:@"%@", error.localizedDescription]);
        } else {
            NSLog(@"Installation succeeded.");
        }
    }];

    [installer.progress addObserver:self forKeyPath:@"fractionCompleted" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"fractionCompleted"] && [object isKindOfClass:[NSProgress class]]) {
        NSProgress *progress = (NSProgress *)object;
        NSLog(@"Installation progress: %f.", progress.fractionCompleted * 100);

        if (progress.finished) {
            [progress removeObserver:self forKeyPath:@"fractionCompleted"];
        }
    }
}

// MARK: - Public methods.

// Create a bundle on the user's Home directory to store any artifacts that
// the installation produces.
- (void)setUpVirtualMachineArtifacts
{
    createVMBundle();
}

// MARK: Begin macOS installation.

- (void)installMacOS:(NSURL *)ipswURL
{
    NSLog(@"Attempting to install from IPSW at %s\n", [ipswURL fileSystemRepresentation]);
    [VZMacOSRestoreImage loadFileURL:ipswURL completionHandler:^(VZMacOSRestoreImage *restoreImage, NSError *error) {
        if (error) {
            abortWithErrorMessage(error.localizedDescription);
        }

        VZMacOSConfigurationRequirements *macOSConfiguration = restoreImage.mostFeaturefulSupportedConfiguration;
        if (!macOSConfiguration || !macOSConfiguration.hardwareModel.supported) {
            abortWithErrorMessage(@"No supported Mac configuration.");
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self setupVirtualMachineWithMacOSConfigurationRequirements:macOSConfiguration];
            [self startInstallationWithRestoreImageFileURL:ipswURL];
        });
    }];
}

@end

#endif
