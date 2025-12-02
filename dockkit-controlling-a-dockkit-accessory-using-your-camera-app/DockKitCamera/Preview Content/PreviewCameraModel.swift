/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A camera implementation to use when working with SwiftUI previews.
*/

import Foundation
import SwiftUI

@Observable
class PreviewCameraModel: Camera {
    struct PreviewSourceStub: PreviewSource {
        // This is stubbed out for test purposes.
        func connect(to target: PreviewTarget) {}
    }
    
    let previewSource: PreviewSource = PreviewSourceStub()
    
    private(set) var status = CameraStatus.unknown
    private(set) var cameraOrientation: CameraOrientation = .unknown
    private(set) var captureActivity = CaptureActivity.idle
    private(set) var zoomFactor = 1.0
    var isRecording: Bool = false
    private(set) var isSwitchingModes = false
    private(set) var isVideoDeviceSwitchable = true
    private(set) var isSwitchingVideoDevices = false
    private(set) var thumbnail: CGImage?
    
    var error: Error?
    
    init(status: CameraStatus = .unknown) {
        self.status = status
    }
    
    func start() async {
        if status == .unknown {
            status = .running
        }
    }
    
    func switchVideoDevices() {
        logger.debug("Device switching isn't implemented in PreviewCamera.")
    }
    
    func toggleRecording() {
        logger.debug("Moving capture isn't implemented in PreviewCamera.")
    }
    
    var recordingTime: TimeInterval { .zero }
    
    func setTrackingServiceDelegate(_ service: any DockAccessoryTrackingDelegate) async {
        logger.debug("Setting tracking service isn't implemented in PreviewCamera.")
    }
    
    func devicePointConverted(from point: CGPoint) async -> CGPoint { return point }
}
