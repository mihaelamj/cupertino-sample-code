/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that manages DockKit accessories and their control.
*/

import Foundation
import AVFoundation
import Combine
#if canImport(DockKit)
import DockKit
#endif
import UIKit
import Spatial

/// An object that manages DockKit accessories and their control.
/// The app defines it as an `actor` type to ensure that all camera operations happen off the `@MainActor`.
actor DockControlService {
    /// A value that indicates the current connection and tracking status of the DockKit accesssory.
    @Published private(set) var status: DockAccessoryStatus = .disconnected
    
    /// A value that indicates the current battery status, if available.
    @Published private(set) var battery: DockAccessoryBatteryStatus = .unavailable
    
    /// The current region of interest.
    @Published private(set) var regionOfInterest = CGRect.zero
    
    /// The currently tracked people.
    @Published private(set) var trackedPersons: [DockAccessoryTrackedPerson] = []
    
#if !targetEnvironment(simulator)
    // The currently connected DockKit accessory.
    private var dockkitAccessory: DockAccessory? = nil
#endif
    
    // A task that subscribes to battery events.
    private var batterySummaryTask: Task<(), Never>? = nil
    
    // A task that subscribes to tracking summary events.
    private var trackingSummaryTask: Task<(), Never>? = nil
    
    // A task subscribes to accessory events.
    private var accessoryEventsTask: Task<(), Never>? = nil
    
    // The current DockKit tracking mode.
    private var trackingMode: TrackingMode = .system
    
    // True if DockKit is performing an animation.
    private var animating: Bool = false
    
#if !targetEnvironment(simulator)
    // The current tracking summary state.
    private var lastTrackingSummary: DockAccessory.TrackingState? = nil
    
    // The current battery state.
    private var lastBatteryState: DockAccessory.BatteryState? = nil
#endif
    
    // A delegate to perform capture.
    private(set) weak var cameraCaptureDelegate: CameraCaptureDelegate?
    
    // Record the last shutter event.
    private var lastShutterEventTime: Date = .now
    
    // Update features, if necessary.
    private weak var features: DockAccessoryFeatures? = nil
    
    // MARK: - DockKit setup
    /// Subscribe to accessory connection and tracking state changes.
    func setUp(features: DockAccessoryFeatures) async {
#if !targetEnvironment(simulator)
        self.features = features
        do {
            // Subscribe to accessory state changes.
            for await stateEvent in try DockAccessoryManager.shared.accessoryStateChanges {
                // Handle the docked/undocked status.
                if let dockkitAccessory = dockkitAccessory, dockkitAccessory == stateEvent.accessory {
                    if stateEvent.state != .docked {
                        cleanupAccessoryStates()
                        status = .disconnected
                        self.dockkitAccessory = nil
                        continue
                    }
                } else {
                    // Save the DockKit accessory when docked (connected).
                    if let newAccessory = stateEvent.accessory, stateEvent.state == .docked {
                        dockkitAccessory = newAccessory
                        await setupAccessorySubscriptions(for: newAccessory)
                    }
                }
                
                // Set the status according to the tracking button state.
                if stateEvent.trackingButtonEnabled {
                    status = .connectedTracking
                } else {
                    status = .connected
                    // Clear the tracking summary.
                    trackedPersons = []
                }
            }
        } catch {
            logger.error("Error setting up DockKit session : \(error)")
        }
#endif
    }
    
#if !targetEnvironment(simulator)
    /// Subscribe to accessory button events like shutter, flip, and zoom.
    private func subscribeToAccessoryEvents(for accesory: DockAccessory) {
        // Subscribe to the asynchronous stream of `accessoryEvents` in a task.
        accessoryEventsTask = Task {
            do {
                for await event in try accesory.accessoryEvents {
                    switch event {
                    case let .button(id, pressed):
                        // Log the custom button event.
                        logger.notice("Got button event \(id): \(pressed ? "pressed" : "unpressed")")
                    case .cameraZoom(factor: let factor):
                        let zoomType = factor > 0 ? CameraZoomType.increase : CameraZoomType.decrease
                        // Implement the camera zoom.
                        cameraCaptureDelegate?.zoom(type: zoomType, factor: 0.2)
                    case .cameraShutter:
                        if Date.now.timeIntervalSince(lastShutterEventTime) > 0.2 {
                            // Implement the camera start capture or stop capture.
                            cameraCaptureDelegate?.startOrStartCapture()
                            lastShutterEventTime = .now
                        }
                    case .cameraFlip:
                        // Implement the camera flip.
                        cameraCaptureDelegate?.switchCamera()
                    default: break
                    }
                }
            } catch {
                logger.error("Error listening for accessory events")
            }
        }
    }

    /// Set up accessory subscriptions to the asynchronous stream of events.
    private func setupAccessorySubscriptions(for accesory: DockAccessory) async {
        do {
            // Enable system tracking on the first connection.
            try await DockAccessoryManager.shared.setSystemTrackingEnabled(true)
        } catch {
            logger.error("Error enabling system tracking")
        }
        // Start the necessary subscriptions to accessory events and battery states.
        subscribeToAccessoryEvents(for: accesory)
        toggleBatterySummary(to: true)
    }
#endif
    
    // MARK: - DockKit tracking
    /// Change the subject framing to one of the framing modes.
    func updateFraming(to framing: FramingMode) async -> Bool {
#if !targetEnvironment(simulator)
        guard let accessory = dockkitAccessory else {
            logger.error("No DockKit accessory connected")
            return false
        }
        do {
            // Set the DockKit `FramingMode` to correspond to all framing modes.
            try await accessory.setFramingMode(dockKitFramingMode(from: framing))
        } catch {
            logger.error("Error setting framing mode to \(framing.rawValue)")
            return false
        }
#endif
        return true
    }
    
    /// Change the subject framing to one of the the tracking modes.
    ///
    /// System tracking is turned off when the tracking mode is custom or manual.
    func updateTrackingMode(to trackingMode: TrackingMode) async -> Bool {
#if !targetEnvironment(simulator)
        self.trackingMode = trackingMode
        do {
            // Call `systemTrackingEnabled` with `true` to enable the system tracking mode.
            try await DockAccessoryManager.shared.setSystemTrackingEnabled(trackingMode == .system ? true : false)
        } catch {
            logger.error("Error setting tracking mode to \(trackingMode.rawValue)")
            return false
        }
#endif
        return true
    }
    
    /// Select the subject to track at a specific point in the image.
    ///
    /// Reset if the point is nil.
    func selectSubject(at point: CGPoint?) async -> Bool {
#if !targetEnvironment(simulator)
        guard let accessory = dockkitAccessory else {
            logger.error("No DockKit accessory connected")
            return false
        }
        
        do {
            if let point = point {
                // Select a specific subject at the point.
                try await accessory.selectSubject(at: point)
            } else {
                // Clear the selected subjects.
                try await accessory.selectSubjects([])
            }
        } catch {
            logger.error("Error selecting subject at (\(point?.x ?? 0.0), \(point?.y ?? 0.0)): \(error)")
            return false
        }
#endif
        return true
    }
    
    /// Set the region of interest to track in the image.
    ///
    //// The app sets this when it's going to crop the image it receives from `AVCapture`.
    func setRegionOfInterest(to region: CGRect) async -> Bool {
#if !targetEnvironment(simulator)
        guard let accessory = dockkitAccessory else {
            logger.error("No DockKit accessory connected")
            return false
        }
    
        do {
            // Set the region of interest to frame the subjects in.
            try await accessory.setRegionOfInterest(region)
        } catch {
            logger.error("Error setting the region of interest to (\(region.midX), \(region.midY)) with size (\(region.width), \(region.height)): \(error)")
            return false
        }
#endif
        return true
    }
    
    /// Perform a precanned animation.
    func animate(_ animation: Animation) async -> Bool {
#if !targetEnvironment(simulator)
        guard let dockkitAccessory = dockkitAccessory else {
            logger.error("No DockKit accessory connected")
            return false
        }
        
        // Return if `DockAccessory` is performing an animation.
        if animating {
            logger.error("DockKit accessory busy animating")
            return false
        }
        
        do {
            animating = true
            // Disable the system tracking before running an animation.
            try await DockAccessoryManager.shared.setSystemTrackingEnabled(false)
            
            // Run the animation and wait for it to finish.
            let progress = try await dockkitAccessory.animate(motion: dockKitAnimation(from: animation))
            while !progress.isCancelled && !progress.isFinished {
                try await Task.sleep(nanoseconds: NSEC_PER_SEC / 10) // 0.1 sec
            }
            
            // Restore the system tracking after running the animation.
            try await DockAccessoryManager.shared.setSystemTrackingEnabled(trackingMode == .system ? true : false)
        } catch {
            logger.error("Error executing animation \(animation.rawValue) : \(error)")
            try? await DockAccessoryManager.shared.setSystemTrackingEnabled(trackingMode == .system ? true : false)
            animating = false
            return false
        }
        
        animating = false
#endif
        return true
    }
    
    /// Track if custom tracking is turned on.
    ///
    /// The app calls this if it's going to track a specific observation it detects as an `AVMetadataObject`.
    /// The app needs to turn off the system tracking.
    func track(metadata: [AVMetadataObject], sampleBuffer: CMSampleBuffer,
               deviceType: AVCaptureDevice.DeviceType, devicePosition: AVCaptureDevice.Position) async {
#if !targetEnvironment(simulator)
        let orientation = await getCameraOrientation()
        
        if DockAccessoryManager.shared.isSystemTrackingEnabled {
            logger.notice("System tracking is enabled, ignoring command")
            return
        }
        
        guard let dockkitAccessory = dockkitAccessory else {
            logger.error("No DockKit accessory connected")
            return
        }
        
        // Return if `DockAccessory` is performing an animation.
        if animating {
            logger.error("DockKit accessory busy animating")
            return
        }
        
        // Get the image buffer from `CMSampleBuffer`.
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            logger.error("Error getting pixel buffer")
            return
        }
        
        // Get `referenceDimensions` from `ImageBuffer`.
        let referenceDimensions = CGSize(width: Double(CVPixelBufferGetWidth(pixelBuffer)),
                                          height: Double(CVPixelBufferGetHeight(pixelBuffer)))
        
        // Get the camera intrinsics attachment from `CMSampleBuffer`.
        var cameraIntrinsics: matrix_float3x3? = nil
        if let cameraIntrinsicsUnwrapped = CMGetAttachment(sampleBuffer,
                                                           key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix,
                                                           attachmentModeOut: nil) as? Data {
            cameraIntrinsics = cameraIntrinsicsUnwrapped.withUnsafeBytes { $0.load(as: matrix_float3x3.self) }
        }
        
        // Construct the `CameraInformation` structure.
        let cameraInfo = DockAccessory.CameraInformation(captureDevice: deviceType, cameraPosition: devicePosition, orientation: orientation,
                                                         cameraIntrinsics: cameraIntrinsics, referenceDimensions: referenceDimensions)
        
        // Perform DockKit tracking.
        if let imageBuffer = sampleBuffer.imageBuffer {
            Task {
                try await dockkitAccessory.track(metadata, cameraInformation: cameraInfo, image: imageBuffer)
            }
        } else {
            Task {
                try await dockkitAccessory.track(metadata, cameraInformation: cameraInfo)
            }
        }
#endif
    }
    
    // MARK: - DockKit summary subscriptions
    /// Turn the subscription on or off for the tracking summary of the DockKit accessory.
    func toggleTrackingSummary(to enable: Bool) {
#if !targetEnvironment(simulator)
        // Cancel the previous task.
        trackingSummaryTask?.cancel()
        trackingSummaryTask = nil
        
        if enable {
            
            guard let dockkitAccessory = dockkitAccessory else {
                logger.error("No DockKit accessory connected")
                // Reset the feature to update the UI.
                self.features?.isTrackingSummaryEnabled = false
                return
            }
            
            trackingSummaryTask = Task {
                do {
                    for await trackingSummaryState in try dockkitAccessory.trackingStates {
                        self.lastTrackingSummary = trackingSummaryState
                        
                        var trackedPersons: [DockAccessoryTrackedPerson] = []
                        for subject in trackingSummaryState.trackedSubjects {
                            // Save the tracking state for all subjects that are people.
                            switch subject {
                            case .person(let person):
                                if let rect = await cameraCaptureDelegate?.convertToViewSpace(from: person.rect) {
                                    // Create a `DockAccessoryTrackedPerson` object from `TrackingState`.
                                    trackedPersons.append(DockAccessoryTrackedPerson(saliency: person.saliencyRank,
                                                                                     rect: rect,
                                                                                     speaking: person.speakingConfidence,
                                                                                     looking: person.lookingAtCameraConfidence))
                                    print("pos: \(person.rect.minX) \(person.rect.minY)")
                                }
                            default:
                                // Do nothing.
                                break
                            }
                        }
                        
                        self.trackedPersons = trackedPersons
                    }
                } catch {
                    logger.error("Error getting tracking summary from \(dockkitAccessory.debugDescription)")
                    // Reset the feature to update the UI.
                    self.features?.isTrackingSummaryEnabled = false
                }
            }
        } else {
            self.trackedPersons = []
            // Reset the feature to update the UI.
            self.features?.isTrackingSummaryEnabled = false
        }
#endif
    }
    
    /// Turn the subscription on or off for the battery summary of the DockKit accessory.
    func toggleBatterySummary(to enable: Bool) {
#if !targetEnvironment(simulator)
        if enable {
            
            if batterySummaryTask != nil {
                logger.log("battery summary task already running, not starting a new one")
                return
            }
            
            guard let dockkitAccessory = dockkitAccessory else {
                logger.error("No DockKit accessory connected")
                return
            }
            
            batterySummaryTask = Task {
                do {
                    logger.notice("subscribing to batterySummaryState")
                    // Subscribe to the asynchronous sequence `batteryStates`.
                    for await batterySummaryState in try dockkitAccessory.batteryStates {
                        // Publish the battery update to the UI.
                        battery = .available(percentage: batterySummaryState.batteryLevel, charging: batterySummaryState.chargeState == .charging)
                    }
                } catch {
                    logger.error("Error getting battery states summary from \(dockkitAccessory.debugDescription)")
                }
                
            }
        } else {
            // Publish the battery update to the UI.
            battery = .unavailable
            batterySummaryTask?.cancel()
            batterySummaryTask = nil
        }
#endif
    }
    
    // MARK: - DockKit manual control
    func handleChevronTapped(chevronType: ChevronType, speed: Double = 0.2) async {
#if !targetEnvironment(simulator)
        if trackingMode != .manual {
            // tracking has to be in manual mode to use chevrons.
            return
        }
        
        guard let dockkitAccessory = dockkitAccessory else {
            logger.error("No DockKit accessory connected")
            return
        }
        
        var velocity = Vector3D()
        
        do {
            // Rotate `DockAccessory` according to the chevron (corrected to the camera orientation).
            switch chevronType {
            case .tiltUp:
                velocity.x = -speed
            case .tiltDown:
                velocity.x = speed
            case .panLeft:
                velocity.y = -speed
            case .panRight:
                velocity.y = speed
            }
            try await dockkitAccessory.setAngularVelocity(velocity)
        } catch {
            logger.error("Error executing chevron \(chevronType.rawValue) tap")
        }
#endif
    }
    
    // MARK: - Cleanup
    private func cleanupAccessoryStates() {
        // When the accessory disconnects and reconnects, update the features to reflect the default.
        features?.isSetROIEnabled = false
        features?.isTapToTrackEnabled = false
        features?.framingMode = .auto
        features?.trackingMode = .system
        // Cancel the subscription to the battery state.
        toggleBatterySummary(to: false)
        // Reset `trackedPersons` to clear the `trackingState` UI.
        trackedPersons = []
    }
    
    // MARK: - Camera-capture delegate
    /// Set the camera-capture delegate.
    func setCameraCaptureServiceDelegate(_ delegate: CameraCaptureDelegate) {
        cameraCaptureDelegate = delegate
    }
    
    // MARK: - Private helpers
    
#if !targetEnvironment(simulator)
    /// Convert to the corresponding DockKit framing mode.
    private func dockKitFramingMode(from framingMode: FramingMode) -> DockAccessory.FramingMode {
        switch framingMode {
        case .auto:
            return DockAccessory.FramingMode.automatic
        case .center:
            return DockAccessory.FramingMode.center
        case .left:
            return DockAccessory.FramingMode.left
        case .right:
            return DockAccessory.FramingMode.right
        }
    }
    
    /// Convert to the corresponding DockKit animation.
    private func dockKitAnimation(from animation: Animation) -> DockAccessory.Animation {
        switch animation {
        case .yes:
            return DockAccessory.Animation.yes
        case .nope:
            return DockAccessory.Animation.no
        case .wakeup:
            return DockAccessory.Animation.wakeup
        case .kapow:
            return DockAccessory.Animation.kapow
        }
    }
    
    @MainActor
    private func getCameraOrientation() -> DockAccessory.CameraOrientation {
        switch UIDevice.current.orientation {
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        case .landscapeRight:
            return .landscapeRight
        case .landscapeLeft:
            return .landscapeLeft
        case .faceDown:
            return .faceDown
        case .faceUp:
            return .faceUp
        default:
            return .corrected
        }
    }
#endif
    
}

/// Mark any unchecked sendables to call the DockKit track API to suppress warnings.
extension CVBuffer: @unchecked @retroactive Sendable {

}
