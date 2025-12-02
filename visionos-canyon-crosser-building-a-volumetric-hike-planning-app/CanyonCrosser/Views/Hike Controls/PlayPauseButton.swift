/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The button to play or pause a hike.
*/

import SwiftUI
import RealityKit

// `PlayPauseButton` reads the `isPaused` and `dragState` properties of observable components, resulting in the
// view body being recomputed every time the `hikePlaybackStateComponent` or the `hikerDragStateComponent` is changed.
// Store your state in components that update at similar frequencies and observe changes in the
// smallest possible view as shown with `PlayPauseButton` and `ResetButton`.
struct PlayPauseButton: View {
    @Environment(AppModel.self) var appModel
    let buttonSize: CGFloat

    var body: some View {
        Button {
            appModel.toggleHikePlaybackState()
        } label: {
            Image(systemName: appModel.hikePlaybackStateComponent.isPaused ? "play.fill" : "pause.fill")
                .frame(width: buttonSize, height: buttonSize)
                .contentTransition(.symbolEffect(.replace))
        }
        .disabled(appModel.hikerDragStateComponent.dragState != .none)
    }
}

