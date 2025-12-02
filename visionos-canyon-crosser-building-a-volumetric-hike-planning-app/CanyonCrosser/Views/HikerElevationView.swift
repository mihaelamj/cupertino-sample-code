/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows the hiker's elevation.
*/

import SwiftUI
import Observation
import RealityKit

struct HikerElevationView: View {
    @Environment(AppModel.self) var appModel

    var elevation: Float {
        // These values aren't guaranteed to provide an accurate elevation,
        // but provide an estimate that's relatively close.
        let highAltitude: Float = 6860.0
        let lowAltitude: Float = 2480.0
        let highRealityPosition: Float = 34.4
        let lowRealityPosition: Float = 18.9
        let currPosition = appModel.hikerEntity.observable.position.y

        return lowAltitude + (currPosition - lowRealityPosition) * (highAltitude - lowAltitude) / (highRealityPosition - lowRealityPosition)
    }

    var body: some View {
        HStack {
            Label {
                Text("\(Int(elevation), format: .number)")
                    .contentTransition(.numericText())
            } icon: {
                Image(systemName: "mountain.2.fill")
            }
            .padding(.horizontal)
            .padding()
            .glassBackgroundEffect()
        }
    }
}

fileprivate struct HikerElevationPreviewSettings: View {
    @Environment(AppModel.self) var appModel

    var body: some View {
        VStack {
            Button {
                if appModel.hikerDragStateComponent.dragState == .slider {
                    appModel.hikerDragStateComponent.dragState = .none
                } else {
                    appModel.hikerDragStateComponent.dragState = .slider
                }
            } label: {
                Text("Toggle isDraggingHiker")
            }

            Button {
                withAnimation {
                    appModel.hikerEntity.position.y += 125
                }
            } label: {
                Text("Increase Height")
            }
            Button {
                withAnimation {
                    appModel.hikerEntity.position.y -= 125
                }
            } label: {
                Text("Decrease Height")
            }
        }
        .fixedSize()
        .padding()
        .glassBackgroundEffect()
    }
}

#Preview(traits: .modifier(HikerComponentAppModelData())) {
    HikerElevationView()
    HikerElevationPreviewSettings()
}
