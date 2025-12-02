/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that starts playing a video.
*/

import SwiftUI
import RealityKit

struct ContentView: View {
    let playVideoAction: () -> Void

    var body: some View {
        VStack(spacing: 25) {
            Text("Docking Sample")
                .font(.largeTitle)

            Button(action: playVideoAction) {
                Text("Play Video")
            }
        }
    }
}

#Preview(windowStyle: .automatic) {
    ContentView {
        print("Play Video Tapped")
    }
}

