/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the main camera feed from Apple Vision Pro in a window.
*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainCameraView()
            .padding()
    }
}

#Preview(windowStyle: .automatic) {
    ContentView()
}
