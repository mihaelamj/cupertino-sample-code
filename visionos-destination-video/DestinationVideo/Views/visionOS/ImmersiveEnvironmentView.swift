/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that presents an environment.
*/

import Studio
import SwiftUI
import RealityKit

/// A view that presents an environment.
struct ImmersiveEnvironmentView: View {
    static let id: String = "ImmersiveEnvironmentView"

    @Environment(ImmersiveEnvironment.self) private var immersiveEnvironment
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        RealityView { content in
            if let rootEntity = immersiveEnvironment.rootEntity {
                content.add(rootEntity)
            }
        }
        .onDisappear {
            immersiveEnvironment.immersiveSpaceState = .closed
            immersiveEnvironment.clearEnvironment()
        }
        .onAppear {
            immersiveEnvironment.immersiveSpaceState = .open
        }
        .transition(.opacity)
    }
}
