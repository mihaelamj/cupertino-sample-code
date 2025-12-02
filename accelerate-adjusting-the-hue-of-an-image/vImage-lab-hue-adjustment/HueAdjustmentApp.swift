/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Hue Adjustment app file.
*/
import SwiftUI

@main
struct HueAdjustmentApp: App {
    
    @StateObject private var labHueRotate = LabHueRotate(image: #imageLiteral(resourceName: "Flowers_1.png"))
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(labHueRotate)
        }
    }
}
