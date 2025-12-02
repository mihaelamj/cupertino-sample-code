/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that prompts the user for Calendar full access.
*/

import SwiftUI
import EventKit

struct WelcomeView: View {
    @EnvironmentObject var storeManager: EventStoreManager
    @State private var shouldPresentError: Bool = false
    
    @State private var alertMessage: String?
    @State private var alertTitle: String?
    
    /*
         The app first verifies the authorization status for Calendar events.
         If the user authorized full access to Calendar, the app displays a
         list of events that occur within this month in all the user's calendars.
         If the user denied or restricted access, the app provides the reason.
     */
    var body: some View {
        NavigationStack {
            VStack {
                switch storeManager.authorizationStatus {
                    case .notDetermined:
                        MessageView(message: .none)
                    case .restricted:
                        messageView(with: .restricted)
                    case .denied:
                        messageView(with: .denied)
                    case .fullAccess:
                        EventList()
                    case .writeOnly:
                        messageView(with: .upgrade)
                    case .authorized:
                        EventList()
                    @unknown default:
                        fatalError("An error occurs.")
                }
            }
            .alertErrorMessage(message: alertMessage, title: alertTitle, isPresented: $shouldPresentError)
            .navigationTitle("Your monthly events")
            .task {
                do {
                    try await storeManager.setupEventStore()
                } catch {
                    showError(error, title: "Authorization failed.")
                }
            }
        }
    }
    
    @ViewBuilder
    func messageView(with message: Message) -> some View {
        if !shouldPresentError {
            MessageView(message: message)
        }
    }
    
    /// Set up details of the alert message.
    func showError(_ error: Error, title: String) {
        alertTitle = title
        alertMessage = error.localizedDescription
        shouldPresentError = true
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .environmentObject(EventStoreManager())
    }
}
