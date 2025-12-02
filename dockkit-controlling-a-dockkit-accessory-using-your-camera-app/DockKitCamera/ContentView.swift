/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main user interface for the sample app.
*/

import SwiftUI

struct ContentView<CameraModel: Camera, DockControllerModel: DockController>: View {
    
    @State var camera: CameraModel
    @State var dockController: DockControllerModel
    
    @State var regionOfInterest = CGRect.null
    @State private var isDragging = false
    @State private var dragStart: CGPoint = CGPoint.zero
    @State private var dragCurrent: CGPoint = CGPoint.zero
    
    func drag() -> some Gesture {
        DragGesture()
            .onChanged({ value in
                Task {
                    if self.dragStart == CGPoint.zero {
                        self.dragStart = value.location
                    }
                    self.dragCurrent = value.location
                    self.isDragging = true
                }
            })
            .onEnded({ _ in
                Task {
                    self.isDragging = false
                    let roi = dragRegionOfInterest()
                    if await dockController.setRegionOfInterest(to: await dragRegionOfInterestNormalized(), override: false) {
                        // Update the UI.
                        regionOfInterest = roi
                    } else {
                        // Reset the region of interest.
                        regionOfInterest = CGRect.null
                    }
                    self.dragStart = CGPoint.zero
                }
        })
    }
    
    func minDragPoint() -> CGPoint {
        return CGPoint(x: max(dragStart.x, dragCurrent.x), y: max(dragStart.y, dragCurrent.y))
    }
    
    func dragRegionOfInterestNormalized() async -> CGRect {
        let dragStartNormalized = await camera.devicePointConverted(from: dragStart)
        let dragCurrentNormalized = await camera.devicePointConverted(from: dragCurrent)
        
        let width = abs(dragStartNormalized.x - dragCurrentNormalized.x)
        let height = abs(dragStartNormalized.y - dragCurrentNormalized.y)
        let originX = min(dragStartNormalized.x, dragCurrentNormalized.x)
        let originY = min(dragStartNormalized.y, dragCurrentNormalized.y)
        
        return CGRect(x: originX, y: originY, width: width, height: height)
    }
    
    func dragRegionOfInterest() -> CGRect {
        let width = abs(dragStart.x - dragCurrent.x)
        let height = abs(dragStart.y - dragCurrent.y)
        let originX = min(dragStart.x, dragCurrent.x)
        let originY = min(dragStart.y, dragCurrent.y)
        return CGRect(x: originX, y: originY, width: width, height: height)
    }
    
    var body: some View {
        ZStack {
            // A container view that manages the placement of the preview.
            PreviewContainer(camera: camera) {
                CameraPreview(source: camera.previewSource)
                    .onTapGesture { location in
                        // Select the subject at the device's location if tap-to-track is enabled.
                        Task {
                            let deviceLocation = await camera.devicePointConverted(from: location)
                            _ = await dockController.selectSubject(at: deviceLocation, override: false)
                        }
                    }
                    .simultaneousGesture(drag())
                    .overlay {
                        // The region-of-interest view denotes the region with framed subjects that someone selects.
                        RegionOfInterestView(regionOfInterest: $regionOfInterest, dockController: dockController)
                            .hidden(dockController.dockAccessoryFeatures.isSetROIEnabled == false
                                    || dockController.status == .disconnected)
                    }
                    .overlay {
                        // The view to show a live region-of-interest selection.
                        ClearRectangleWithBorder(rect: dragRegionOfInterest())
                            .hidden(dockController.dockAccessoryFeatures.isSetROIEnabled == false || isDragging == false)
                    }
                    .overlay {
                        // The tracking summary view displays only when the tracking summary option is enabled.
                        // The tracking summary view is hidden when the tracking mode is manual.
                        TrackingSummaryView(trackedPersons: $dockController.trackedPersons)
                            .hidden(dockController.dockAccessoryFeatures.isTrackingSummaryEnabled == false
                                    || dockController.dockAccessoryFeatures.trackingMode == .manual)
                    }
                    // The chevron overlays for manual `DockAccessory` control.
                    .overlay(alignment: .center) {
                        VStack(alignment: .center, spacing: 100) {
                            ChevronView(type: .tiltUp)
                                .highPriorityGesture(
                                    TapGesture()
                                        .onEnded { _ in
                                            Task {
                                                await dockController.handleChevronTapped(chevronType: correctChevronType(.tiltUp),
                                                                                                  speed: nil)
                                            }
                                        }
                                )
                            ChevronView(type: .tiltDown)
                                .highPriorityGesture(
                                    TapGesture()
                                        .onEnded { _ in
                                            Task {
                                                await dockController.handleChevronTapped(chevronType: correctChevronType(.tiltDown),
                                                                                                  speed: nil)
                                            }
                                        }
                                )
                        }
                        .hidden(dockController.dockAccessoryFeatures.trackingMode != .manual || camera.isSwitchingVideoDevices)
                    }
                    .overlay(alignment: .center) {
                        HStack(alignment: .center, spacing: 100) {
                            ChevronView(type: .panLeft)
                                .highPriorityGesture(
                                    TapGesture()
                                        .onEnded { _ in
                                            Task {
                                                await dockController.handleChevronTapped(chevronType: correctChevronType(.panLeft),
                                                                                                  speed: nil)
                                            }
                                        }
                                )
                            ChevronView(type: .panRight)
                                .highPriorityGesture(
                                    TapGesture()
                                        .onEnded { _ in
                                            Task {
                                                await dockController.handleChevronTapped(chevronType: correctChevronType(.panRight),
                                                                                                  speed: nil)
                                            }
                                        }
                                )
                        }
                        .hidden(dockController.dockAccessoryFeatures.trackingMode != .manual || camera.isSwitchingVideoDevices)
                    }
            }
            // The main camera user interface.
            CameraUI(camera: camera, dockController: dockController)
        }
    }
    
    /// Convert the chevron type to a type corrected for the current camera orientation.
    ///
    /// Depending on the current camera orientation, tapping a chevron causes the `DockAccessory` to perform a specific motion.
    /// Convert this to a corrected chevron type and then pass it to the dock control service to perform the correct motion.
    func correctChevronType(_ chevronType: ChevronType) -> ChevronType {
        switch camera.cameraOrientation {
        case .unknown, .portrait:
            return correctChevronTypeForPortrait(chevronType)
        case .portraitUpsideDown:
            return correctChevronTypeForPortraitUpsideDown(chevronType)
        case .landscapeLeft:
            return correctChevronTypeForLandscapeLeft(chevronType)
        case .landscapeRight:
            return correctChevronTypeForLandscapeRight(chevronType)
        }
    }
    
    private func correctChevronTypeForPortrait(_ chevronType: ChevronType) -> ChevronType {
        switch chevronType {
        case .tiltUp:
            return .tiltUp
        case .tiltDown:
            return .tiltDown
        case .panLeft:
            return .panLeft
        case .panRight:
            return .panRight
        }
    }
    
    private func correctChevronTypeForPortraitUpsideDown(_ chevronType: ChevronType) -> ChevronType {
        switch chevronType {
        case .tiltUp:
            return .tiltDown
        case .tiltDown:
            return .tiltUp
        case .panLeft:
            return .panRight
        case .panRight:
            return .panLeft
        }
    }
    
    private func correctChevronTypeForLandscapeLeft(_ chevronType: ChevronType) -> ChevronType {
        switch chevronType {
        case .tiltUp:
            return .panRight
        case .tiltDown:
            return .panLeft
        case .panLeft:
            return .tiltUp
        case .panRight:
            return .tiltDown
        }
    }
    
    private func correctChevronTypeForLandscapeRight(_ chevronType: ChevronType) -> ChevronType {
        switch chevronType {
        case .tiltUp:
            return .panLeft
        case .tiltDown:
            return .panRight
        case .panLeft:
            return .tiltDown
        case .panRight:
            return .tiltUp
        }
    }
}

#Preview {
    ContentView(camera: PreviewCameraModel(), dockController: PreviewDockControllerModel())
}
