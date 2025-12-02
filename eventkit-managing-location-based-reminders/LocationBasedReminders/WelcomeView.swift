/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that verifies the authorization status of the app.
*/

import EventKit
import SwiftUI

struct WelcomeView: View {
    @Environment(ReminderStoreManager.self) private var manager
    
    var body: some View {
        NavigationStack {
            VStack {
                switch manager.authorizationStatus {
                case .fullAccess: MainView()
                case .notDetermined: RequestAccessButton()
                case .denied, .restricted: AppSettingsLink()
                default:
                    fatalError("A fatal error occured.")
                }
            }
            .task {
                await manager.checkDefaultListExists()
            }
            .navigationTitle("Location Reminders")
        }
    }
}

#Preview {
    WelcomeView()
        .environment(ReminderStoreManager())
}
