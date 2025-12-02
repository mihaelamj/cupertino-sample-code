/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The image convolution application file.
*/

import SwiftUI

@main
struct vImageConvolutionApp: App {

    @StateObject private var imageConvolver = ImageConvolver(sourceImage: #imageLiteral(resourceName: "Landscape_4_Waterwheel.jpg"))
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(imageConvolver)
        }
    }
    
}
