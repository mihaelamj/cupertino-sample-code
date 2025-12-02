/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A protocol that represents the model to display DockKit-related views.
*/

import SwiftUI
import AVFoundation

/// A protocol that represents the model to display DockKit-related views.
///
/// The DockKit APIs require a physical device to run. The app defines the model as a protocol to make it
/// simple to swap out the real DockKit accessory for a test DockKit accessory when previewing SwiftUI views.
@MainActor
protocol DockController: AnyObject {
    
    /// Provides the current status of the DockKit accessory.
    var status: DockAccessoryStatus { get }
    
    /// Provides the current battery status of the DockKit accessory.
    var battery: DockAccessoryBatteryStatus { get }
    
    var regionOfInterest: CGRect { get }
    
    /// Provides the currently tracked people in a DockKit session.
    var trackedPersons: [DockAccessoryTrackedPerson] { get set }
    
     /// The dock accessory features that a person can enable in the user interface.
    var dockAccessoryFeatures: DockAccessoryFeatures { get }
    
    /// Starts the DockKit pipeline.
    func start() async
    
    /// Change the DockKit framing to auto, center, left, or right.
    func updateFraming(to framing: FramingMode) async -> Bool
    
    /// Change the DockKit tracking to system, custom, or manual.
    func updateTrackingMode(to trackingMode: TrackingMode) async -> Bool
    
    /// Select the subject closest to a specific point in the camera preview.
    func selectSubject(at point: CGPoint?, override: Bool) async -> Bool
    
    /// Set the region of interest to track.
    func setRegionOfInterest(to region: CGRect, override: Bool) async -> Bool
    
    /// Perform a specific animation.
    func animate(_ animation: Animation) async -> Bool
    
    /// Control the DockKit accessory when a person taps the chevron.
    func handleChevronTapped(chevronType: ChevronType, speed: Double?) async
    
     /// Enable or disable the subscription to the tracking summary.
    func toggleTrackingSummary(to enable: Bool) async
    
    /// Enable or disable the subscription to the battery summary.
    func toggleBatterySummary(to enable: Bool) async
    
   /// Set the camera-capture delegate.
    func setCameraCaptureServiceDelegate(_ delegate: CameraCaptureDelegate) async
}
