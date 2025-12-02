/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
SimpleURLFilterApp represents the main entrypoint and scene configuration for the application.
 The ConfigurationModel is created, held as a property, and given to the Environment for use
 by the ContentView and ConvigurationView.
*/

import SwiftUI

@main
struct SimpleURLFilterApp: App {
    let configurationModel = ConfigurationModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(configurationModel)
        }
    }
}
