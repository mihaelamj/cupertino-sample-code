/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The entry point to the dice sample app.
*/
import SwiftUI

@MainActor
@main
struct DiceSampleApp: App {
    @State var game = Game()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(game)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 2, height: 2, depth: 2, in: .meters)
    }
}
