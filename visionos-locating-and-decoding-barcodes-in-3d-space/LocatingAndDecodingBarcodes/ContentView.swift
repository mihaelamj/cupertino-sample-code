/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to open and close the immersive space.
*/

import SwiftUI
import RealityKit

struct ContentView: View {
    @Environment(AppModel.self) var appModel

    var body: some View {
        VStack {
            if appModel.immersiveSpaceState == .open {
                Text("Look at a Code 128 barcode or a QR code to see the app detect it.")
            } else {
                Text("Barcode detection is only available in an immersive space.")
            }
                    
            ToggleImmersiveSpaceButton()
        }
        .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
        .environment(AppModel())
}
