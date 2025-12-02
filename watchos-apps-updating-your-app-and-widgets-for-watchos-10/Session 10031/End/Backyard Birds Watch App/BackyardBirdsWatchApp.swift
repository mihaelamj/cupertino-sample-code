/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app view of Backyard Birds.
*/

import SwiftUI

@main
struct BackyardBirdsWatchApp: App {
    @StateObject var backyardsData = BackyardsData()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(backyardsData)
        }
    }
}
