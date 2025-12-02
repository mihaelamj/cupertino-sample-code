/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The root content view for the app, displaying the user's flight itinerary.
*/

import SwiftUI

struct ContentView: View {
    @Environment(\.editMode) private var editMode
    @State private var selection: FlightLeg?
    @State private var showBookingForm = false
    @StateObject private var flightData = FlightData()
    
    var body: some View {
        NavigationSplitView {
            // Workaround for a known issue where `NavigationSplitView`
            // and `NavigationStack` fail to update when their contents
            // are conditional. For more information,
            // see the iOS 16 Release Notes. (91311311)"
            ZStack {
                Group {
                    if flightData.segments.isEmpty {
                        Text("No Flights")
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundStyle(.tertiary)
                    } else {
                        FlightItineraryList(
                            selection: $selection,
                            segments: $flightData.segments,
                            onDelete: onDelete)
                    }
                }
                .task {
                    Task.detached { @MainActor in
                        await flightData.load()
                    }
                }
                .navigationTitle("My Flights")
                .sheet(isPresented: $showBookingForm) {
                    BookingFormModal(flightData: flightData)
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                            .disabled(flightData.segments.isEmpty)
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Spacer()
                            Button {
                                showBookingForm.toggle()
                            } label: {
                                Label("Add Flight", systemImage: "square.and.pencil")
                            }
                            .disabled(isAddFlightButtonDisabled)
                        }
                    }
                }
            }
        } detail: {
            // Workaround for a known issue where `NavigationSplitView`
            // and `NavigationStack` fail to update when their contents
            // are conditional. For more information,
            // see the iOS 16 Release Notes. (91311311)"
            ZStack {
                if let leg = selection {
                    FlightLegDetail(leg: leg)
                }
            }
        }
    }
    
    func onDelete(atOffsets offsets: IndexSet, in segment: FlightSegment) {
        flightData.removeLegs(atOffsets: offsets, in: segment)
    }
    
    var isAddFlightButtonDisabled: Bool {
        editMode?.wrappedValue.isEditing == true
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
