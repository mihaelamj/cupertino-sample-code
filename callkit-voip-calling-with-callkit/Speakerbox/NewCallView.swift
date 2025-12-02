/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The new call view.
*/

import SwiftUI

struct NewCallView: View {

    struct NewCallDetails {
        var handle = ""
        var isVideo = false
        var delay = 0

        var isValid: Bool {
            handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }
    }

    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var callsController: SpeakerboxCallManager
    @State private var newCallDetails = NewCallDetails(delay: 5)

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("")) {
                    HStack {
                        Text("Destination")

                        TextField("Handle", text: $newCallDetails.handle)
                            .keyboardType(.emailAddress)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Text("Video Call")
                        Toggle(isOn: $newCallDetails.isVideo, label: { EmptyView() })
                    }

                    if !isOutgoing {
                        HStack {
                            Text("Delay \(newCallDetails.delay) seconds")
                            Stepper(value: $newCallDetails.delay, in: 0...100, label: { EmptyView() })
                        }
                    }
                }
            }
            .navigationBarTitle(titleText, displayMode: .inline)
            .navigationBarItems(leading: cancelButton, trailing: dialButton)
        }
    }

    var titleText: Text {
        Text(isOutgoing ? "New Outgoing Call" : "Simulate Incoming Call")
    }

    var cancelButton: some View {
        Button(action: cancelButtonAction) {
            Text("Cancel")
        }
    }

    var dialButton: some View {
        Button(action: dialButtonAction) {
            Text("Dial")
        }
        .disabled(!newCallDetails.isValid)
    }

    /// Indicates if the call is outgoing.
    let isOutgoing: Bool

    /// Creates a new call based on if the call is outgoing or incoming.
    func dialButtonAction() {
        if isOutgoing {
            createNewOutgoingCall(with: newCallDetails)
        } else {
            simulateIncomingCall(with: newCallDetails)
        }

        presentationMode.wrappedValue.dismiss()
    }

    /// Cancels the call and dismisses this view.
    func cancelButtonAction() {
        presentationMode.wrappedValue.dismiss()
    }

    /// Creates a new outgoing call with the specified details.
    /// - Parameter newCallDetails: The call details, including the caller's phone number and if the call includes video
    func createNewOutgoingCall(with newCallDetails: NewCallDetails) {
        callsController.startCall(handle: newCallDetails.handle, video: newCallDetails.isVideo)
    }

    /// Simulates an incoming call with the specified details.
    /// - Parameter newCallDetails: The call details, including the caller's phone number and if the call includes video
    func simulateIncomingCall(with newCallDetails: NewCallDetails) {
        let backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)

        DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + Double(newCallDetails.delay)) {
            AppDelegate.shared.displayIncomingCall(uuid: UUID(), handle: newCallDetails.handle, hasVideo: newCallDetails.isVideo) { _ in
                UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            }
        }
    }

}
