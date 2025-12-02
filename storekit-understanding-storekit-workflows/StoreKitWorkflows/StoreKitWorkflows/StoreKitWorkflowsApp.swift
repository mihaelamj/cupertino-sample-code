/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The top level app structure.
*/

import SwiftUI

@main
struct StoreKitWorkflowsExampleApp: App {
    @State private var store = Store()
    var body: some Scene {
        WindowGroup {
            ContentView().environment(store)
            #if os(macOS)
                .toolbar(removing: .title)
                .toolbarBackgroundVisibility(.automatic, for: .windowToolbar)
                .frame(minWidth: Constants.contentWindowWidth, maxWidth: .infinity, minHeight: Constants.contentWindowHeight, maxHeight: .infinity)
            #endif
        }
    }
}
