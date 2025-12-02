/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The YpCbCr saturation adjustment application file.
*/

import SwiftUI

@main
struct YpCbCrAdjustmentApp: App {
    
    @StateObject private var yCbCrAdjustment = YpCbCrAdjustment(image: #imageLiteral(resourceName: "Rainbow_1.png"))
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(yCbCrAdjustment)
        }
    }
}
