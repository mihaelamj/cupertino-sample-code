/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app definition.
*/

import SwiftUI

/// The entry point for the app that contains the app's single scene.
///
/// The app creates an instance of ``Model`` using the
/// [`StateObject`](https://developer.apple.com/documentation/swiftui/StateObject)
/// property wrapper, and initializes it with ``Model/startData``. The app then
/// shares the model with the entire view hierarchy using the
/// [`environmentObject(_:)`](https://developer.apple.com/documentation/swiftui/view/environmentObject(_:))
/// view modifier.
@main
struct CustomLayoutSampleApp: App {
    // Initialize a data model with zero votes for everyone.
    @StateObject private var model: Model = Model.startData

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
