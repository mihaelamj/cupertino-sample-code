/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main entry for the app.
*/

import SwiftUI
import SwiftData

@main
struct SwiftDataFlashCardSample: App {
    var body: some Scene {
        #if os(iOS) || os(macOS)
        DocumentGroup(editing: .flashCards, migrationPlan: FlashCardsMigrationPlan.self) {
            ContentView()
        }
        #else
        WindowGroup {
            ContentView()
                .modelContainer(previewContainer)
        }
        #endif
    }
}
