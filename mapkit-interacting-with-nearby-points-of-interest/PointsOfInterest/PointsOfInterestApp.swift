/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app structure.
*/

import SwiftData
import SwiftUI

@main
struct PointsOfInterestApp: App {
    
    @State private var locationService = LocationService.shared
   
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(locationService)
        }
    }
}
