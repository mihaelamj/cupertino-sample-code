/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app declaration, specifying the window group and SwiftData container for
  recipes.
*/

import SwiftUI
import SwiftData

@main
struct SampleRecipeEditorApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Recipe.self)
    }
}
