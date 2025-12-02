/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point for the app.
*/

import SwiftUI

@main
struct WatchTaskListSampleApp: App {
    
    @StateObject var itemListModel = ItemListModel()
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(itemListModel)
        }
    }
}
