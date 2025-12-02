/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A helper class to install a macOS virtual machine.
*/

import Virtualization

#if arch(arm64)

class MacOSVirtualMachineInstaller: NSObject {
    private var installationObserver: NSKeyValueObservation?
    private var virtualMachine: VZVirtualMachine!
    private var virtualMachineResponder: MacOSVirtualMachineDelegate?

    // Create a bundle on the user's Home directory to store any artifacts
    // that the installation produces.
    public func setUpVirtualMachineArtifacts() {
        createVMBundle()
    }

    // MARK: Install macOS onto the virtual machine from IPSW.

    public func installMacOS(ipswURL: URL) {
        NSLog("Attempting to install from IPSW at \(ipswURL).")
        VZMacOSRestoreImage.load(from: ipswURL, completionHandler: { [self](result: Result<VZMacOSRestoreImage, Error>) in
            switch result {
                case let .failure(error):
                    fatalError(error.localizedDescription)

                case let .success(restoreImage):
                    installMacOS(restoreImage: restoreImage)
            }
        })
    }

    // MARK: - Internal helper functions.

    private func installMacOS(restoreImage: VZMacOSRestoreImage) {
        guard let macOSConfiguration = restoreImage.mostFeaturefulSupportedConfiguration else {
            fatalError("No supported configuration available.")
        }

        if !macOSConfiguration.hardwareModel.isSupported {
            fatalError("macOSConfiguration configuration isn't supported on the current host.")
        }

        DispatchQueue.main.async { [self] in
            setupVirtualMachine(macOSConfiguration: macOSConfiguration)
            startInstallation(restoreImageURL: restoreImage.url)
        }
    }

    // MARK: Create the Mac platform configuration.

    private func createMacPlatformConfiguration(macOSConfiguration: VZMacOSConfigurationRequirements) -> VZMacPlatformConfiguration {
        let macPlatformConfiguration = VZMacPlatformConfiguration()

        guard let auxiliaryStorage = try? VZMacAuxiliaryStorage(creatingStorageAt: auxiliaryStorageURL,
                                                                    hardwareModel: macOSConfiguration.hardwareModel,
                                                                          options: []) else {
            fatalError("Failed to create auxiliary storage.")
        }
        macPlatformConfiguration.auxiliaryStorage = auxiliaryStorage
        macPlatformConfiguration.hardwareModel = macOSConfiguration.hardwareModel
        macPlatformConfiguration.machineIdentifier = VZMacMachineIdentifier()

        // Store the hardware model and machine identifier to disk so that you
        // can retrieve them for subsequent boots.
        try! macPlatformConfiguration.hardwareModel.dataRepresentation.write(to: hardwareModelURL)
        try! macPlatformConfiguration.machineIdentifier.dataRepresentation.write(to: machineIdentifierURL)

        return macPlatformConfiguration
    }

    // MARK: Create the virtual machine configuration and instantiate the virtual machine.

    private func setupVirtualMachine(macOSConfiguration: VZMacOSConfigurationRequirements) {
        let virtualMachineConfiguration = VZVirtualMachineConfiguration()

        virtualMachineConfiguration.platform = createMacPlatformConfiguration(macOSConfiguration: macOSConfiguration)
        virtualMachineConfiguration.cpuCount = MacOSVirtualMachineConfigurationHelper.computeCPUCount()
        if virtualMachineConfiguration.cpuCount < macOSConfiguration.minimumSupportedCPUCount {
            fatalError("CPUCount isn't supported by the macOS configuration.")
        }

        virtualMachineConfiguration.memorySize = MacOSVirtualMachineConfigurationHelper.computeMemorySize()
        if virtualMachineConfiguration.memorySize < macOSConfiguration.minimumSupportedMemorySize {
            fatalError("memorySize isn't supported by the macOS configuration.")
        }

        // Create a 128 GB disk image.
        createDiskImage()

        virtualMachineConfiguration.bootLoader = MacOSVirtualMachineConfigurationHelper.createBootLoader()

        virtualMachineConfiguration.audioDevices = [MacOSVirtualMachineConfigurationHelper.createSoundDeviceConfiguration()]
        virtualMachineConfiguration.graphicsDevices = [MacOSVirtualMachineConfigurationHelper.createGraphicsDeviceConfiguration()]
        virtualMachineConfiguration.networkDevices = [MacOSVirtualMachineConfigurationHelper.createNetworkDeviceConfiguration()]
        virtualMachineConfiguration.storageDevices = [MacOSVirtualMachineConfigurationHelper.createBlockDeviceConfiguration()]

        virtualMachineConfiguration.pointingDevices = [MacOSVirtualMachineConfigurationHelper.createPointingDeviceConfiguration()]
        virtualMachineConfiguration.keyboards = [MacOSVirtualMachineConfigurationHelper.createKeyboardConfiguration()]

        try! virtualMachineConfiguration.validate()

        if #available(macOS 14.0, *) {
            try! virtualMachineConfiguration.validateSaveRestoreSupport()
        }

        virtualMachine = VZVirtualMachine(configuration: virtualMachineConfiguration)
        virtualMachineResponder = MacOSVirtualMachineDelegate()
        virtualMachine.delegate = virtualMachineResponder
    }

    // MARK: Begin macOS installation.

    private func startInstallation(restoreImageURL: URL) {
        let installer = VZMacOSInstaller(virtualMachine: virtualMachine, restoringFromImageAt: restoreImageURL)

        NSLog("Starting installation.")
        installer.install(completionHandler: { (result: Result<Void, Error>) in
            if case let .failure(error) = result {
                fatalError(error.localizedDescription)
            } else {
                NSLog("Installation succeeded.")
            }
        })

        // Observe installation progress.
        installationObserver = installer.progress.observe(\.fractionCompleted, options: [.initial, .new]) { (progress, change) in
            NSLog("Installation progress: \(change.newValue! * 100).")
        }
    }

    private func createVMBundle() {
        do {
            try FileManager.default.createDirectory(atPath: vmBundlePath, withIntermediateDirectories: false)
        } catch {
            fatalError("Failed to create “VM.bundle.”")
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
    @available(macOS 16.0, *)
    private func createASIFDiskImage() {
        do {
            let process = try Process.run(URL(fileURLWithPath: "/usr/sbin/diskutil"),
                                          arguments: ["image", "create", "blank",
                                                      "--fs", "none", "--format",
                                                      "ASIF", "--size", "128GiB",
                                                      diskImageURL.path])
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                fatalError("Failed to create the disk image.")
            }
        } catch {
            fatalError("Failed to launch diskutil: \(error.localizedDescription)")
        }
    }

    private func createRAWDiskImage() {
        let diskFd = open(diskImageURL.path, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR)
        if diskFd == -1 {
            fatalError("Cannot create disk image.")
        }

        // 128 GB disk space.
        var result = ftruncate(diskFd, 128 * 1024 * 1024 * 1024)
        if result != 0 {
            fatalError("ftruncate() failed.")
        }

        result = close(diskFd)
        if result != 0 {
            fatalError("Failed to close the disk image.")
        }
    }

    private func createDiskImage() {
        if #available(macOS 16.0, *) {
            createASIFDiskImage()
        } else {
            createRAWDiskImage()
        }
    }
}

#endif
