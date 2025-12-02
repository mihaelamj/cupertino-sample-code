/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view of the app.
*/

import SwiftUI

struct MainView: View {

    @EnvironmentObject var callsController: SpeakerboxCallManager
    @State var isPresentingNewOutgoingCall = false
    @State var isPresentingSimulateIncomingCall = false

    var body: some View {
        NavigationView {
            Group {
                if callsController.calls.isEmpty {
                    EmptyCallsView()
                } else {
                    CallsListView()
                }
            }
            .navigationBarTitle("Speakerbox", displayMode: .inline)
            .navigationBarItems(trailing: newCallButtons)
        }
    }

    /// Returns an HStack containing buttons to initiate outgoing and simulated incoming calls.
    var newCallButtons: some View {
        HStack {
            Button(action: { self.isPresentingNewOutgoingCall = true }) {
                Image(systemName: "phone.fill.arrow.up.right")
            }
            .sheet(isPresented: self.$isPresentingNewOutgoingCall) {
                NewCallView(isOutgoing: true)
                    .environmentObject(self.callsController)
            }
            .padding(.trailing)

            Button(action: { self.isPresentingSimulateIncomingCall = true }) {
                Image(systemName: "phone.fill.arrow.down.left")
            }
            .sheet(isPresented: self.$isPresentingSimulateIncomingCall) {
                NewCallView(isOutgoing: false)
                    .environmentObject(self.callsController)
            }
            .padding(10)
        }
    }

}
