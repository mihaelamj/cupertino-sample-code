/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main entry point.
*/
 
import SwiftUI

@main
struct SpatialPhotosSampleApp: App {
    @State private var appModel = AppModel()
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
                .frame(minWidth: 600, maxWidth: 2000, minHeight: 600, maxHeight: 2000)
        }
        .windowResizability(.contentSize)
        .windowStyle(.plain)
    }
}
