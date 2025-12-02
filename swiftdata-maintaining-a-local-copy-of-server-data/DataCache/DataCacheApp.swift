/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main entry point of the DataCache app.
*/

import SwiftUI
import SwiftData

/// The main entry point of the DataCache app.
@main
struct DataCacheApp: App {
    @State private var viewModel = ViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
        }
        .modelContainer(for: Quake.self)
    }
}
