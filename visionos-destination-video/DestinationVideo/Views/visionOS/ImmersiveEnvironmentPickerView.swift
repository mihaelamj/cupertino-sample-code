/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that adds the custom environments to the immersive environment picker in an undocked video player view controller.
*/

import SwiftUI

/// A view that populates the ImmersiveEnvironmentPicker in an undocked AVPlayerViewController.
struct ImmersiveEnvironmentPickerView: View {

    var body: some View {
        StudioButton(state: .dark)
        StudioButton(state: .light)
    }
}

/// A view for the buttons that appear in the environment picker menu.
private struct StudioButton: View {
    @Environment(ImmersiveEnvironment.self) private var immersiveEnvironment
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var state: EnvironmentStateType

    var body: some View {
        Button {
            immersiveEnvironment.requestEnvironmentState(state)
            Task {
                guard await immersiveEnvironment.loadEnvironment() else { return }

                immersiveEnvironment.immersiveSpaceState = .inTransition
                switch await openImmersiveSpace(id: ImmersiveEnvironmentView.id) {
                case .opened:
                    // Don't set immersiveSpaceState to .open because there
                    // may be multiple paths to ImmersiveView.onAppear().
                    // Only set .open in ImmersiveView.onAppear().
                    break

                case .userCancelled, .error:
                    // On error, we need to mark the immersive space
                    // as closed because it failed to open.
                    fallthrough
                @unknown default:
                    // On unknown response, assume space did not open.
                    immersiveEnvironment.immersiveSpaceState = .closed
                }
            }
        } label: {
            Label {
                Text("Studio", comment: "Show Studio environment")
            } icon: {
                Image(["studio_thumbnail", state.displayName.lowercased()].joined(separator: "_"))
            }
            Text(state.displayName)
        }
    }
}
