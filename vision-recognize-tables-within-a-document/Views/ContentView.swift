/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Displays the camera for the document reader app.
*/

import SwiftUI
import FoundationModels

struct ContentView: View {
    @State private var camera = Camera()
    @State var imageData: Data? = nil

    var body: some View {
        if let image = imageData {
            ImageView(imageData: image)
        } else {
            CameraView(camera: camera, imageData: $imageData)
                .task {
                    // Start the capture pipeline.
                    await camera.start()
                }
        }
    }
}

#Preview {
    ContentView()
}
