/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SVD image compression application.
*/

import SwiftUI

@main
struct SVDImageCompressionApp: App {
    
    @StateObject private var imageCompressor = SVDImageCompressor(image: #imageLiteral(resourceName: "Flowers_square.jpeg"))

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(imageCompressor)
        }
    }
}
