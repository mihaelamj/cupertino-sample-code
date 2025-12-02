/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view containing the immersive reality view.
*/

import RealityKit
import SwiftUI

/// The view that contains the contents of the immersive space.
struct ImmersiveView: View {
    /// The app's observable data model.
    @Environment(AppModel.self) private var appModel

    /// The subscription to the playback completed animation event when the cube moves back to
    /// the position in the volumetric window.
    @State private var subscriptionToMoveCompleted: EventSubscription?
    
    var body: some View {
        createImmersiveSpaceRealityView()
            .gesture(appModel.dragUpdateTransforms)
            .gesture(doubleTapMove)
            .onAppear {
                appModel.immersiveSpaceState = .open
            }
            .onDisappear {
                appModel.immersiveSpaceState = .closed
            }
    }
    
    /// Creates the reality view for the immersive space.
    /// - Returns: The reality view for the immersive space.
    private func createImmersiveSpaceRealityView() -> some View {
        RealityView { content in
            
            // Add the root entity of the immersive space to the content.
            content.add(appModel.immersiveSpaceRootEntity)
            
            // Subscribe to the animation event when the volume cube
            // moves back to the last recorded position in the volumetric window.
            subscriptionToMoveCompleted = content.subscribe(
                to: AnimationEvents.PlaybackCompleted.self,
                on: appModel.volumeCube,
                onMoveCompleted)
        }
    }

    /// Move the cube from the immersive space to the volumetric window with a double-tap gesture.
    var doubleTapMove: some Gesture {
        TapGesture(count: 2)
            .onEnded { _ in
                appModel.moveCubeFromImmersiveSpaceToVolumetricWindow()
            }
    }
    
    /// Handle the playback completed event when the cube has completed the move from the immersive space to the volumetric window.
    /// - Parameter event: The playback completed animation event.
    /// Note that the method doesn't use the `event` argument, but exists to conform to the expected argument in the subscription.
    private func onMoveCompleted(_ event: AnimationEvents.PlaybackCompleted) {
        appModel.makeCubeSubEntityOfVolumeRoot()
    }
}

#Preview(immersionStyle: .full) {
    ImmersiveView()
        .environment(AppModel())
}
