/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main entry point of the iOS app.
*/

import SwiftUI

@main
struct CommunicationNotificationsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
