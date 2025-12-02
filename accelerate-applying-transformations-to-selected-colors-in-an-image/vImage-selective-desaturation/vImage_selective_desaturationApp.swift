/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The selective desaturator app file.
*/

import SwiftUI

@main
struct SelectiveDesaturationApp: App {
    
    @StateObject private var selectiveDesaturator = SelectiveDesaturator()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(selectiveDesaturator)
        }
    }
}

