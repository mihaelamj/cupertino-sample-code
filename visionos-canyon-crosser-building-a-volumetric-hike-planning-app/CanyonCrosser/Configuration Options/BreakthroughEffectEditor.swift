/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An editor for changing the breakthrough effect.
*/

import SwiftUI
struct BreakthroughEffectEditor: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel
        EditorSection(title: Text("Breakthrough Effect")) {
            Text("Toolbar Settings:")

            Picker("Picker", selection: $appModel.debugSettings.toolbarBreakthroughEffectOption, content: {
                Text("Subtle").tag(DebugSettings.BreakthroughOption.subtle)
                Text("Prominent").tag(DebugSettings.BreakthroughOption.prominent)
                Text("None").tag(DebugSettings.BreakthroughOption.none)
            })
            .pickerStyle(.segmented)

            Text("Popover Settings:")

            Picker("Picker", selection: $appModel.debugSettings.popoverBreakthroughEffectOption, content: {
                Text("Subtle").tag(DebugSettings.PopoverBreakthroughOption.subtle)
                Text("Subtle + Opacity").tag(DebugSettings.PopoverBreakthroughOption.subtlePlusOpacity)
                Text("Prominent").tag(DebugSettings.PopoverBreakthroughOption.prominent)
                Text("None").tag(DebugSettings.PopoverBreakthroughOption.none)
            })
            .pickerStyle(.segmented)
        }
        .padding()
    }
}

#Preview {
    BreakthroughEffectEditor()
        .environment(AppModel())
        .frame(width: 600)
        .glassBackgroundEffect()
}
