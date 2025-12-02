/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An editor for the alignment of the timeline view.
*/

import SwiftUI

struct TimelineViewEditor: View {
    @Environment(AppModel.self) var appModel

    var body: some View {
        @Bindable var appModel = appModel

        EditorSection(title: Text("Timeline Ornament Options")) {
            VStack {
                Text("Scene Anchor:")
                SceneAnchorSelector(unitPoint: $appModel.debugSettings.ornamentSceneAnchorOverride)

                Text("Content Alignment:")
                ContentAlignmentSelector(alignment3D: $appModel.debugSettings.ornamentContentAlignmentOverride)

                Toggle(isOn: $appModel.debugSettings.controlsMovesToFrontWhenSnapped) {
                    Text("Controls Move to the Front When Snapped")
                }
            }
        }
    }

    struct ContentAlignmentSelector: View {
        @Binding var alignment3D: Alignment3D?

        var body: some View {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                ToggleButton(selected: $alignment3D, desired: .top, named: ".top")
                ToggleButton(selected: $alignment3D, desired: .center, named: ".center")
                ToggleButton(selected: $alignment3D, desired: .bottom, named: ".bottom")
            }
        }
    }

    struct SceneAnchorSelector: View {
        @Binding var unitPoint: UnitPoint3D?

        var body: some View {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                ToggleButton(selected: $unitPoint, desired: .center, named: ".center")
                ToggleButton(selected: $unitPoint, desired: .top, named: ".top")
                ToggleButton(selected: $unitPoint, desired: .back, named: ".back")
                ToggleButton(selected: $unitPoint, desired: .bottomFront, named: ".bottomFront")
                ToggleButton(selected: $unitPoint, desired: .front, named: ".front")
                ToggleButton(selected: $unitPoint, desired: .topFront, named: ".topFront")
                ToggleButton(selected: $unitPoint, desired: .topBack, named: ".topBack")
                ToggleButton(selected: $unitPoint, desired: .bottomBack, named: ".bottomBack")
            }
        }
    }

    struct ToggleButton<ToggleType: Equatable>: View {
        @Binding var selected: ToggleType?
        let desired: ToggleType
        let named: String

        var body: some View {
            Toggle(isOn: .init(get: {
                selected == desired
            }, set: { _ in
                selected = selected == desired ? nil : desired
            }), label: {
                Text(named)
            })
            .toggleStyle(.button)
            .font(.caption)
        }
    }
}

#Preview {
    TimelineViewEditor()
        .glassBackgroundEffect()
        .environment(AppModel())
}
