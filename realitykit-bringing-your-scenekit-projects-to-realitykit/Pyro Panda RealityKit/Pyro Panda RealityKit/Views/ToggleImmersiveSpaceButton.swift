/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A toggle that allows someone to turn the immersive space on and off.
*/

import SwiftUI

@available(iOS, unavailable)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(visionOS, introduced: 26.0)
struct ToggleImmersiveSpaceButton: View {

    @Environment(AppModel.self) private var appModel

    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var onTransitionComplete: ((_ newState: AppModel.ImmersiveSpaceState) -> Void)?

    var body: some View {
        Button {
            Task { @MainActor in
                switch appModel.immersiveSpaceState {
                case .open:
                    appModel.immersiveSpaceState = .inTransition
                    await dismissImmersiveSpace()
                    // Don't set `immersiveSpaceState` to `.closed` because there
                    // are multiple paths to `ImmersiveView.onDisappear()`.
                    // Only set `.closed` in `ImmersiveView.onDisappear()`.

                    onTransitionComplete?(.closed)

                case .closed:
                    appModel.immersiveSpaceState = .inTransition
                    switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
                    case .opened:
                        // Don't set `immersiveSpaceState` to `.open` because there
                        // may be multiple paths to `ImmersiveView.onAppear()`.
                        // Only set `.open` in `ImmersiveView.onAppear()`.
                        break

                    case .userCancelled, .error:
                        // On error, the system marks the immersive space
                        // as closed because it failed to open.
                        fallthrough
                    @unknown default:
                        // On unknown response, assume the space didn't open.
                        appModel.immersiveSpaceState = .closed
                    }

                    onTransitionComplete?(.open)

                case .inTransition:
                    // The app disables the button in this case.
                    break
                }
            }
        } label: {
            if appModel.immersiveSpaceState == .open {
                Image(systemName: "arrow.down.right.and.arrow.up.left")
            } else {
                Text("Play Game")
            }
        }
        .disabled(appModel.immersiveSpaceState == .inTransition)
        .animation(.none, value: 0)
        .fontWeight(.semibold)
    }
}
