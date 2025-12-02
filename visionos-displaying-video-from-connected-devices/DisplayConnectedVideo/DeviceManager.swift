/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's video device interface.
*/

@preconcurrency import AVFoundation

@MainActor
@Observable
class DeviceManager {
    /// A preview layer that presents the captured video frames.
    let preview = AVSampleBufferDisplayLayer()
    
    /// An object that manages the capture pipeline.
    private let captureManager: CaptureManager
    
    /// An object that manages the list of connected UVC devices.
    private let connectionManager = ConnectionManager()
    
    /// A list a available capture devices.
    private(set) var devices: [Device] = []
    
    /// The authorization status for camera access when the app launched.
    /// This is set twice when the app is launched for the first time. Initially to `AVCaptureDevice.notDetermined`
    /// then to a value that reflects the choice a person made when prompted for authorization.
    private(set) var initialAuthorizationStatus: AVAuthorizationStatus
    
    /// The selected capture device.
    var selectedDevice: Device? {
        didSet {
            Task {
                await captureManager.select(device: selectedDevice)
            }
        }
    }
    
    init() {
        // Create the capture manager passing it the object to enqueue sample buffers for rendering.
        captureManager = CaptureManager(videoRenderer: preview.sampleBufferRenderer)
        
        initialAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        Task {
            if initialAuthorizationStatus == .notDetermined {
                await AVCaptureDevice.requestAccess(for: .video)
                
                initialAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
            }
        }
        
        Task {
            // Monitor updates to the device list.
            for await devices in connectionManager.devices {
                self.devices = devices
            }
        }
    }
    
    /// Start capturing video from the selected device.
    func start() async {
        await captureManager.start()
    }
}
