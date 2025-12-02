/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that shows custom immersive environment options.
*/

import SwiftUI

struct ImmersivePickerView: View {
    let appModel: AppModel

    /// An asynchronous call returns after dismissing the immersive space.
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    /// An asynchronous call returns after opening the immersive space.
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some View {
        // Add a button to toggle the immersive environment.
        Button("Sky Dome", systemImage: "photo") {
            Task {
                if appModel.immersiveSpaceState == .open {
                    await dismissImmersiveSpace()
                } else {
                    await openImmersiveSpace(id: appModel.immersiveSpaceID)
                }
            }
        }
    }
}
