/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The placeholders and device compatibility views for this game.
*/

import SwiftUI

extension PyroPandaView {
    var supportsFullGame: Bool {
        #if os(visionOS)
        true
        #else
        appModel.metalDevice?.supportsFamily(.apple2) ?? false
        #endif
    }

    func loadingPlaceholder() -> some View {
        ZStack {
            Color("Backgrounds")
            VStack {
                Image("Loading")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Backgrounds"))
        .onDisappear {
            appModel.displayOverlaysVisible = true
        }
    }

    func gameNotSupportedUI() -> some View {
        ZStack {
            Color("Backgrounds")
            VStack {
                Spacer()
                Image("Sorry")
                Spacer()
                Text("Your device can't run this game.")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("Backgrounds"))
    }
}
