/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The load event view that displays all generated events as a list.
*/

import Charts
import EnergyKit
import SwiftUI

/// The load event view that displays all generated events as a list.
struct LoadEventsView: View {
    @Environment(ElectricVehicleController.self) private var model

    @State private var alertMessage = ""
    @State private var isSending = false
    @State private var showAlert = false
    var body: some View {
        List(model.events.sorted { $0.timestamp < $1.timestamp }) { event in
            NavigationLink(destination: LoadEventDetailView(event: event)) {
                LoadEventListItem(event: event)
            }
        }
        .overlay {
            if model.events.isEmpty {
                ContentUnavailableView {
                    Label("No EV Load Events", systemImage: "bolt.circle")
                } description: {
                    Text("Generated load events will appear here.")
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle("Load Events")
        .toolbar(content: toolbarContent)
        .alert(
            "Load Events Status",
            isPresented: $showAlert
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }

    }
}

// MARK: Toolbar Content

extension LoadEventsView {
    private func setIsSending(_ isSending: Bool) {
        self.isSending = isSending
    }
    private func setAlertMessage(_ message: String) {
        self.alertMessage = message
    }
    private func setShowAlert(_ show: Bool) {
        self.showAlert = show
    }
    private func purgeEvents() {
        self.model.events = []
    }
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            SendButton {
                Task.detached {
                    do {
                        await setShowAlert(false)
                        await setIsSending(true)
                        try await model.submitEvents()
                        await purgeEvents()
                        await setIsSending(false)
                        await setAlertMessage("Successfully sent load events!")
                        await setShowAlert(true)
                    } catch {
                        await setAlertMessage("Failed to send load events: \(error.localizedDescription)")
                        await setShowAlert(true)
                    }
                }
            }
            .disabled(isSending)

            Spacer()
            LoadEventsToolbarStatus(
                eventsCount: model.events.count
            )
        }
    }
}
