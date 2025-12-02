/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that exposes runtime options.
*/

import SwiftUI

struct SettingsView: View {

    @Binding var appModel: AppModel

    var body: some View {
        List {
            if AppModel.supportsMSAA {
                Toggle(isOn: $appModel.useMSAA, label: { Text("Use MSAA") })
            }
            Toggle(isOn: $appModel.withHover, label: { Text("Hover effects") })
                .enableOnlyOnVisionOS26()
            Toggle(isOn: $appModel.withBackground, label: { Text("With background") })
            Toggle(isOn: $appModel.overrideResolution, label: { Text("Override resolution") })
                .enableOnlyOnVisionOS26()
            if appModel.overrideResolution {
                Slider(value: $appModel.resolution, in: 0...1)
            }
            Toggle(isOn: $appModel.foveation, label: { Text("Foveation") })
            HStack {
                Text("Debug colors")
                Slider(value: $appModel.debugFactor, in: 0...1, label: { EmptyView() })
            }
        }
    }
}

