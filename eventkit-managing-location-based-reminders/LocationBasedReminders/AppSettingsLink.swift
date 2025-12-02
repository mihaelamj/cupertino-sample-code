/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app settings link view.
*/

import EventKit
import SwiftUI

struct AppSettingsLink: View {
    @Environment(\.openURL) private var openURL
    @Environment(ReminderStoreManager.self) private var manager
    
    var body: some View {
        VStack {
            if manager.authorizationStatus == .denied {
                noAccessView
            } else if manager.authorizationStatus == .restricted {
                restrictedView
            }
        }
    }
    
    /// Takes the person to the Settings app on their device, where they can change permission settings for the app.
    private func navigatetoSettings() {
         guard let destination = URL(string: UIApplication.openSettingsURLString) else {
         fatalError("Expected a valid URL.")
         }
         openURL(destination)
    }
    
    private var navigateButton: some View {
        Button {
            navigatetoSettings()
        } label: {
            Text("Go to Settings")
        }
    }
    
    /// The app shows this view when the person denies the app access to reminders.
    private var noAccessView: some View {
        ContentUnavailableView {
            Label("No Access", systemImage: "lock.fill")
        } description: {
            let status = "The app doesn't have permission to access reminders."
            let action = "Please grant the app access in Settings so the app can read and write your location-based reminders."
            Text("\(status) \(action)")
                .multilineTextAlignment(.leading)
        } actions: {
            navigateButton
        }
    }
    
    /// The app shows this view when access to reminders is restricted and the person can't grant access.
    private var restrictedView: some View {
        ContentUnavailableView {
            Label("Restricted Access", systemImage: "lock.fill")
        } description: {
            Text("This device doesn't allow access to reminders.")
        }
    }
}
