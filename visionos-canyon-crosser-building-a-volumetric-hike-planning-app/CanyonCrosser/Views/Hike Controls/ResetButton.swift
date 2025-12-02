/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The button to reset a hike.
*/

import SwiftUI
import RealityKit

// This view reads the `hikeProgress` and `dragState` properties of observable components, resulting in the view
// body being recomputed every time the `hikePlaybackStateComponent` or the `hikerProgressComponent` is changed.
// Since the `hikerProgressComponent` is changed on every update when the hike is played back, the view body is also
// executed on every update. Monitoring changes that occur on every frame update may become a concern for complex views.
// Store your state in components that update at similar frequencies and observe changes in the
// smallest possible view as shown with `PlayPauseButton` and `ResetButton`.
struct ResetButton: View {
    @Environment(AppModel.self) var appModel
    let buttonSize: CGFloat
    @State private var resetProgress: Bool = false

    var body: some View {
        Button {
            resetProgress.toggle()
            appModel.resetHike()
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .frame(width: buttonSize, height: buttonSize)
                .symbolEffect(.rotate, options: .speed(4).nonRepeating, value: resetProgress)
        }
        .disabled(appModel.hikerProgressComponent.hikeProgress < 0.001)
        .disabled(appModel.hikerDragStateComponent.dragState != .none)
    }
}
