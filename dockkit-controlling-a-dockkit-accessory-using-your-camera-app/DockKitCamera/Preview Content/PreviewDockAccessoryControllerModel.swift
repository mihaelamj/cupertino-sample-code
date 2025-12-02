/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A dock accessory controller implementation to use when working with SwiftUI previews.
*/

import Foundation
import SwiftUI

@Observable
class PreviewDockControllerModel: DockController {
    
    var status: DockAccessoryStatus = .disconnected
    
    var battery: DockAccessoryBatteryStatus = .unavailable
    
    var regionOfInterest: CGRect = CGRect.zero
    
    var dockAccessoryFeatures: DockAccessoryFeatures = DockAccessoryFeatures()
    
    var trackedPersons: [DockAccessoryTrackedPerson] = []
    
    init() {
        //
    }
    
    func start() async {
        logger.debug("Start isn't implemented in PreviewDockAccessory.")
    }
    
    func updateFraming(to framing: FramingMode) async -> Bool {
        logger.debug("updateFraming isn't implemented in PreviewDockAccessory.")
        return false
    }
    
    func updateTrackingMode(to trackingMode: TrackingMode) async -> Bool {
        logger.debug("updateTrackingMode isn't implemented in PreviewDockAccessory.")
        return false
    }
    
    func selectSubject(at point: CGPoint?, override: Bool = false) async -> Bool {
        logger.debug("selectSubject isn't implemented in PreviewDockAccessory.")
        return false
    }
    
    func setRegionOfInterest(to region: CGRect, override: Bool = false) async -> Bool {
        logger.debug("setRegionOfInterest isn't implemented in PreviewDockAccessory.")
        return false
    }
    
    func animate(_ animation: Animation) async -> Bool {
        logger.debug("animate isn't implemented in PreviewDockAccessory.")
        return false
    }
    
    func handleChevronTapped(chevronType: ChevronType, speed: Double?) async {
        logger.debug("handleChevronTapped isn't implemented in PreviewDockAccessory.")
    }
    
    func toggleTrackingSummary(to enable: Bool) async {
        logger.debug("toggleTrackingSummary isn't implemented in PreviewDockAccessory.")
    }
    
    func toggleBatterySummary(to enable: Bool) async {
        logger.debug("toggleBatterySummary isn't implemented in PreviewDockAccessory.")
    }
    
    func setCameraCaptureServiceDelegate(_ delegate: any CameraCaptureDelegate) async {
        logger.debug("setCameraCaptureServiceDelegate isn't implemented in PreviewDockAccessory.")
    }
    
}
