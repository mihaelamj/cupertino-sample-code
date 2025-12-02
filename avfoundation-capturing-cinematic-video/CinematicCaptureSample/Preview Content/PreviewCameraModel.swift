/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Camera implementation to use when working with SwiftUI previews.
*/

import Foundation
import SwiftUI
import Combine
import CoreMedia
import AVFoundation

@Observable
class PreviewCameraModel: Camera {

    let preview = CALayer()
    
    let metadataManager = CinematicMetadataManager()

    var metadataObjects: AsyncStream<[CinematicFocusMetadata]>
    private let metadataObjectsContinuation: AsyncStream<[CinematicFocusMetadata]>.Continuation
    
    var sampleBuffers: AsyncStream<CMSampleBuffer>
    private let sampleBufferContinuation: AsyncStream<CMSampleBuffer>.Continuation?
    
    var prefersMinimizedUI = false
    
    var simulatedAperture: Float = 4.5
    var maxSimulatedAperture: Float = 16.0
    var minSimulatedAperture: Float = 2.0
    func changeSimulatedAperture(_ simulatedAperture: Float) async { }

    private(set) var status = CameraStatus.unknown
    private(set) var captureActivity = CaptureActivity.idle
    var captureMode = CaptureMode.previewLayer {
        didSet {
            isSwitchingModes = true
            Task {
                // Create a short delay to mimic the time it takes to reconfigure the session.
                try? await Task.sleep(until: .now + .seconds(0.3), clock: .continuous)
                self.isSwitchingModes = false
            }
        }
    }
    private(set) var isSwitchingModes = false
    private(set) var isVideoDeviceSwitchable = true
    private(set) var isSwitchingVideoDevices = false
    private(set) var thumbnail: CGImage?
    
    var error: Error?
    
    func changeFocus(at point: CGPoint, fixedFocus: Bool) async { }
    
    func tapPreview(at point: CGPoint) async { }
    
    func longPressPreview(at point: CGPoint) async { }
    
    init(captureMode: CaptureMode = .previewLayer, status: CameraStatus = .unknown) {
        self.captureMode = captureMode
        self.status = status
        let (sampleBuffers, sampleBufferContinuation) = AsyncStream.makeStream(of: CMSampleBuffer.self)
        self.sampleBuffers = sampleBuffers
        self.sampleBufferContinuation = sampleBufferContinuation
        
        let (metadataObjects, metadataObjectsContinuation) = AsyncStream.makeStream(of: [CinematicFocusMetadata].self)
        self.metadataObjects = metadataObjects
        self.metadataObjectsContinuation = metadataObjectsContinuation
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
    
    func syncState() async {
        logger.debug("Syncing state isn't implemented in PreviewCamera.")
    }
}
