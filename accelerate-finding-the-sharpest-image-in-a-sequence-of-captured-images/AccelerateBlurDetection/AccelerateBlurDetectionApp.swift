/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The blur detection app file.
*/

import SwiftUI

@main
struct AccelerateBlurDetectionApp: App {
    
    @StateObject private var blurDetectorResultModel = BlurDetectorResultModel()
    @StateObject private var blurDetector = BlurDetector()
    
    var body: some Scene {
        WindowGroup {
            BlurDetectorView()
                .environmentObject(blurDetectorResultModel)
                .environmentObject(blurDetector)
        }
    }
}
