/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that delivers a stream of updates, containing an array of connected devices, when a device connects or disconnects.
*/

import AVFoundation

/*
 A structure that represents a physical capture device.
 AVCaptureDevice` isn't `Sendable`, so create a representation
 to pass across concurrency domains.
*/
struct Device: Identifiable, Hashable {
    let id: String
    let name: String
    
    var captureDevice: AVCaptureDevice {
        // It's safe to force unwrap the result. An instance of this struct
        // wouldn't exist without the underlying `AVCaptureDevice` instance.
        AVCaptureDevice(uniqueID: id)!
    }
}

@MainActor
class ConnectionManager {
    
    /// The list of available capture devices.
    let devices: AsyncStream<[Device]>
    private var continuation: AsyncStream<[Device]>.Continuation?
    
    /// An object that retrieves capture devices.
    private let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.external],
                                                                    mediaType: .video,
                                                                    position: .unspecified)
    
    init() {
        
        let (devices, continuation) = AsyncStream.makeStream(of: [Device].self)
        self.devices = devices
        self.continuation = continuation
                
        updateDeviceList()
        observeDeviceConnectionStates()
    }
    
    private func observeDeviceConnectionStates() {
        Task {
            // Await notification of the system connecting a new device.
            for await _ in NotificationCenter.default.notifications(named: AVCaptureDevice.wasConnectedNotification) {
                updateDeviceList()
            }
        }
        
        Task {
            // Await notification of the system disconnecting a device.
            for await _ in NotificationCenter.default.notifications(named: AVCaptureDevice.wasDisconnectedNotification) {
                updateDeviceList()
            }
        }
    }
    
    private func updateDeviceList() {
        // Transform the `AVCaptureDevice` instances.
        let devices = discoverySession
            .devices
            .map { Device(id: $0.uniqueID, name: $0.localizedName) }
        // Yield the updated device list.
        continuation?.yield(devices)
    }
}
