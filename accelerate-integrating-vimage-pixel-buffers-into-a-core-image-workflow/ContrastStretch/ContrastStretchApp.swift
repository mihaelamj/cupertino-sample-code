/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app file for the ends-in contrast-stretching app.
*/

import SwiftUI

@main
struct ContrastStretchApp: App {
    
    @StateObject private var contrastStretcher = ContrastStretcher()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(contrastStretcher)
        }
    }
}
