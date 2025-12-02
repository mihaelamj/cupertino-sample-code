/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app, which creates a scene that contains a window group, displaying
  the root content view.
*/

import SwiftUI

@main
struct FocusCookbookApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 800, height: 600)
        #endif
        .commands {
            SidebarCommands()
            RecipeCommands()
        }
    }
}
