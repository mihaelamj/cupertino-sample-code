/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that provides the interface to the features of the connected DockKit accessory.
*/

import SwiftUI
import Combine
import AVFoundation

#if canImport(DockKit)
import DockKit
#endif

/// An object that provides the interface to the features of the connected DockKit accessory.
///
/// This object provides the default implementation of the `DockAccessory` protocol, which defines the interface
/// to configure the connected DockKit accessory and control it. `DockAccessoryModel` doesn't control the DockKit accessory by itself, but is an
/// `@Observable` type that mediates interactions between the app's SwiftUI views and `DockControlService`.
///
/// For SwiftUI previews and Simulator, the app uses `PreviewDockAccessoryModel` instead.
///
@Observable
final class DockControllerModel: DockController {
    
    /// The current status of the DockKit accessory.
    private(set) var status: DockAccessoryStatus = .disconnected
    
    /// The current battery status of the DockKit accessory.
    private(set) var battery: DockAccessoryBatteryStatus = .unavailable
    
    /// The currently tracked people.
    var trackedPersons: [DockAccessoryTrackedPerson] = []
    
    private(set) var regionOfInterest: CGRect = CGRect.zero
    
    /// The `dockAccessory` features that a person can enable in the user interface.
    private(set) var dockAccessoryFeatures = DockAccessoryFeatures()
    
    /// An object that manages the app's DockKit functionality.
    private let dockControlService = DockControlService()
    
    init() {
        start()
    }
    
    func start() {
        Task {
            await dockControlService.setUp(features: dockAccessoryFeatures)
        }
        // Observe states for UI updates.
        observeState()
    }
    
    // MARK: - DockKit tracking
    
    func updateFraming(to framing: FramingMode) async -> Bool {
        return await dockControlService.updateFraming(to: framing)
    }
    
    func updateTrackingMode(to trackingMode: TrackingMode) async -> Bool {
         await dockControlService.updateTrackingMode(to: trackingMode)
    }
    
    func selectSubject(at point: CGPoint?, override: Bool = false) async -> Bool {
        if dockAccessoryFeatures.isTapToTrackEnabled == false && !override {
            logger.error("Enable tap to track from DockKit menu to select subject.")
            return false
        }
        return await dockControlService.selectSubject(at: point)
    }
    
    func setRegionOfInterest(to region: CGRect, override: Bool = false) async -> Bool {
        if dockAccessoryFeatures.isSetROIEnabled == false && !override {
            logger.error("Enable set Region of Interest(ROI) from DockKit menu to set ROI")
            return false
        }
        return await dockControlService.setRegionOfInterest(to: region)
    }
    
    func animate(_ animation: Animation) async -> Bool {
        return await dockControlService.animate(animation)
    }
    
    func handleChevronTapped(chevronType: ChevronType, speed: Double?) async {
        if let speed = speed {
            return await dockControlService.handleChevronTapped(chevronType: chevronType, speed: speed)
        }
        
        return await dockControlService.handleChevronTapped(chevronType: chevronType)
    }
    
    func toggleTrackingSummary(to enable: Bool) async {
        await dockControlService.toggleTrackingSummary(to: enable)
    }
    
    func toggleBatterySummary(to enable: Bool) async {
        await dockControlService.toggleBatterySummary(to: enable)
    }
    
    // MARK: - Internal state observations
    // Set up the DockKit state observations.
    private func observeState() {
        
        observeAccessoryConnectionState()
        observeBatteryState()
        observeRegionOfInterestUpdate()
        observeTrackedPersonsState()
    }
    
    private func observeAccessoryConnectionState() {
        Task {
            // Await new status values from the dock controller service.
            for await statusUpdate in await dockControlService.$status.values {
                // Forward the activity to the UI.
                status = statusUpdate
            }
        }
    }
    
    private func observeBatteryState() {
        Task {
            // Await new battery values from the dock controller service.
            for await batteryUpdate in await dockControlService.$battery.values {
                // Forward the activity to the UI.
                battery = batteryUpdate
            }
        }
    }
    
    private func observeRegionOfInterestUpdate() {
        Task {
            for await regionOfInterestUpdate in await dockControlService.$regionOfInterest.values {
                regionOfInterest = regionOfInterestUpdate
            }
        }
    }
    
    private func observeTrackedPersonsState() {
        Task {
            for await trackedPersonsUpdate in await dockControlService.$trackedPersons.values {
                for person in trackedPersonsUpdate {
                    let orientation = UIDevice.current.orientation
                    if orientation == .landscapeLeft || orientation == .landscapeRight {
                        person.rect = CGRect(x: person.rect.origin.x,
                                             y: person.rect.origin.y,
                                             width: person.rect.height,
                                             height: person.rect.width)
                    }
                }
                
                trackedPersons = trackedPersonsUpdate
            }
        }
    }
    
    // MARK: - Camera-capture delegate
    /// Set the camera-capture delegate.
    func setCameraCaptureServiceDelegate(_ delegate: CameraCaptureDelegate) async {
        await dockControlService.setCameraCaptureServiceDelegate(delegate)
    }
}

extension DockControllerModel: DockAccessoryTrackingDelegate {
    func track(metadata: [AVMetadataObject], sampleBuffer: CMSampleBuffer?,
               deviceType: AVCaptureDevice.DeviceType, devicePosition: AVCaptureDevice.Position) {
        guard dockAccessoryFeatures.trackingMode == .custom else {
            return
        }
        
        guard let sampleBuffer = sampleBuffer else {
            return
        }
        
        Task {
            await dockControlService.track(metadata: metadata, sampleBuffer: sampleBuffer,
                                           deviceType: deviceType, devicePosition: devicePosition)
        }
    }
}

extension CMSampleBuffer: @unchecked @retroactive Sendable {
    
}
