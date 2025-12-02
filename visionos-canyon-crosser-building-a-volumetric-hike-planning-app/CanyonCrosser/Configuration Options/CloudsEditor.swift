/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An editor for enabling the clouds and their margins in the scene.
*/

import SwiftUI

struct CloudsEditor: View {
    @Environment(AppModel.self) var appModel
    @State private var cloudsEnabled: Bool = true

    var body: some View {
        EditorSection(title: Text("Clouds")) {
            @Bindable var appModel = appModel

            Toggle(isOn: $cloudsEnabled, label: {
                Text("Clouds \(cloudsEnabled ? "On" : "Off")")
            })

            if cloudsEnabled {
                Text("Extended volume bounds percentage: \(Int(appModel.extendedBoundsMultiplier * 100), format: .percent)")
                Slider(value: $appModel.extendedBoundsMultiplier, in: 0.05...0.5)
            }
        }
        .onChange(of: cloudsEnabled) { _, new in
            appModel.cloudsEntity.isEnabled = new
        }
    }
}

#Preview {
    CloudsEditor()
        .glassBackgroundEffect()
        .environment(AppModel())
}
