/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The window containing the content library.
*/

import SwiftUI

struct LibraryWindow: Scene {
    static let sceneID = "LibraryWindow"

    var body: some Scene {
        WindowGroup(id: LibraryWindow.sceneID) {
            ContentView()
                .padding()
        }
    }
}
