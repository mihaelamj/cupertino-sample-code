/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app, which creates a scene that contains a window group, displaying
 the root content view.
*/

import SwiftUI

@main
struct NavigationCookbookApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                #if os(macOS)
                .frame(minWidth: 800, minHeight: 600)
                #endif
        }
        #if os(macOS)
        .commands {
            SidebarCommands()
        }
        #endif
    }
}
