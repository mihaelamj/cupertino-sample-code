/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app's main window, which presents the UI for the current stage.
*/

import SwiftUI

struct GuessTogetherWindow: Scene {
    @Environment(AppModel.self) var appModel
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainView()
            }
            .frame(width: 900, height: 600)
            .nameAlert()
        }
        .windowResizability(.contentSize)
    }
}
