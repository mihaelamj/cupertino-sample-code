/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays all DockKit controls and options in a menu.
*/

import SwiftUI

/// A view that displays all DockKit controls and options in a menu.
@MainActor
struct DockKitMenu<DockControllerModel: DockController>: View {
    
    @State var dockController: DockControllerModel
    
    private let mainButtonDimension: CGFloat = 68
    
    @State private var visualize = false
    
    @State private var setROI = false
    
    @State var tapToTrack = false
    
    var body: some View {
        Menu() {
            trackingModeMenu
            framingModeMenu
            animateMenu
            trackingSummaryToggle
            tapToTrackToggle
            regionOfInterestToggle

        } label: {
            Image(systemName: "line.3.horizontal")
        }
        .buttonStyle(DefaultButtonStyle(size: .large))
        .frame(width: largeButtonSize.width, height: largeButtonSize.height)
    }
    
    @ViewBuilder
    var tapToTrackToggle: some View {
        @Bindable var features = dockController.dockAccessoryFeatures
        Toggle(isOn: $features.isTapToTrackEnabled, label: {
            HStack {
                Text("Tap to Track")
                Image(systemName: "hand.tap.fill")
            }
            .onChange(of: features.isTapToTrackEnabled) {
                Task {
                    if features.isTapToTrackEnabled == false {
                        // Reset the subject selection.
                        _ = await dockController.selectSubject(at: nil, override: true)
                    }
                }
            }
        }).menuActionDismissBehavior(.disabled)
        
    }
    
    @ViewBuilder
    var regionOfInterestToggle: some View {
        @Bindable var features = dockController.dockAccessoryFeatures
        Toggle(isOn: $features.isSetROIEnabled, label: {
            HStack {
                Text("Region of Interest")
                Image(systemName: "hand.tap.fill")
            }
            .onChange(of: features.isSetROIEnabled) {
                Task {
                    if features.isSetROIEnabled == false {
                        // Reset the region of interest.
                        _ = await dockController.setRegionOfInterest(to: CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0),
                                                                              override: true)
                    }
                }
            }
        })
        .menuActionDismissBehavior(.disabled)
    }
    
    @ViewBuilder
    var trackingSummaryToggle: some View {
        @Bindable var features = dockController.dockAccessoryFeatures
        Toggle(isOn: $features.isTrackingSummaryEnabled, label: {
            HStack {
                Text("Tracking Summary")
                Image(systemName: "person.3.fill")
            }
            .onChange(of: features.isTrackingSummaryEnabled) {
                Task {
                    _ = await dockController.toggleTrackingSummary(to: features.isTrackingSummaryEnabled )
                }
            }
        }).menuActionDismissBehavior(.disabled)
        
    }
    
    @ViewBuilder
    var trackingModeMenu: some View {
        @Bindable var features = dockController.dockAccessoryFeatures
        Menu {
            Picker("Tracking Mode", selection: $features.trackingMode) {
                ForEach(TrackingMode.allCases) { mode in
                    Text(mode.rawValue)
                }
            }.onChange(of: features.trackingMode) { oldValue, newValue in
                Task {
                    await dockController.updateTrackingMode(to: newValue)
                }
            }
        } label: {
            HStack {
                Text("Tracking Mode")
                Image(systemName: "viewfinder")
            }
        }
    }
    
    @ViewBuilder
    var framingModeMenu: some View {
        @Bindable var features = dockController.dockAccessoryFeatures
        Menu {
            HStack {
                Picker("Framing Mode", selection: $features.framingMode) {
                    ForEach(FramingMode.allCases) { mode in
                        HStack {
                            Text(mode.rawValue)
                        }
                    }
                }.onChange(of: features.framingMode) { oldValue, newValue in
                    Task { await  dockController.updateFraming(to: newValue) }
                }
            }
        } label: {
            HStack {
                Text("Framing Mode")
                Image(systemName: "person.crop.rectangle")
            }
        }
    }
    
    @ViewBuilder
    var animateMenu: some View {
        Menu {
            Button {
                Task { await dockController.animate(.yes) }
            } label: {
                HStack {
                    Text("Yes")
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            Button {
                Task { await dockController.animate(.nope) }
            } label: {
                HStack {
                    Text("No")
                    Image(systemName: "xmark.circle.fill")
                }
            }
            Button {
                Task { await dockController.animate(.wakeup) }
            } label: {
                HStack {
                    Text("Wakeup")
                    Image(systemName: "sun.horizon.circle.fill")
                }
            }
            Button {
                Task { await dockController.animate(.kapow) }
            } label: {
                HStack {
                    Text("Kapow")
                    Image(systemName: "sparkle")
                }
            }
        } label: {
            HStack {
                Text("Animate")
                Image(systemName: "move.3d")
            }
        }
    }
    
}

#Preview {
    DockKitMenu(dockController: PreviewDockControllerModel())
}

