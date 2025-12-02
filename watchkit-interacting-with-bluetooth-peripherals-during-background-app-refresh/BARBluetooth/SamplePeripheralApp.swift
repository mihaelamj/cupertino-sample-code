/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main entry point of the iOS app.
*/

import SwiftUI

@main
struct SamplePeripheralApp: App {
    
    static let name: String = "SamplePeripheral"
    
    /// This delegate manages the life cycle of the app.
    @UIApplicationDelegateAdaptor var delegate: ApplicationDelegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
