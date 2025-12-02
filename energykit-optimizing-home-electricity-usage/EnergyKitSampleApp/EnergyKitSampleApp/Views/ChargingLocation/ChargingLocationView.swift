/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The charging location view that list all added locations.
*/

import EnergyKit
import CoreLocation
import SwiftUI
import SwiftData

struct ChargingLocationView: View {
    @Query(sort: \ChargingLocation.energyVenueName, order: .forward)
    private var chargingLocations: [ChargingLocation]
    @Environment(\.modelContext) var modelContext
    @State private var showAlert: Bool = false
    @State private var selection: ChargingLocation?
    @State private var energyKitError: EnergyKitError = .permissionDenied
    typealias VenueID = UUID
    @State private var energyVenueManagers = [VenueID: EnergyVenueManager]()

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(chargingLocations) { chargingLocation in
                    ChargingLocationListItem(chargingLocation: chargingLocation)
                        .swipeActions(edge: .trailing) {
                            DeleteButton {
                                deleteChargingLocation(chargingLocation)
                            }
                        }
                }
                .onDelete(perform: deleteAllChargingLocations(at:))
            }
            .navigationTitle("Charging Locations")
        } detail: {
            // Proceed to venue details if set
            if let selection {
                // Already onboarded
                if selection.isCECEnabled {
                    let venueID = selection.energyVenueID
                    NavigationStack {
                        if let selectedVenue = energyVenueManagers[venueID] {
                            VenueDetailView()
                                .environment(selectedVenue)
                                .onAppear {
                                    // if you are already monitoring and updating
                                    // guidance, then you should not restart
                                    // the stream each time the view appears
                                    if selectedVenue.guidance == nil {
                                        selectedVenue.startGuidanceMonitoring()
                                    }
                                }
                        }
                    }
                    .task {
                        if energyVenueManagers[venueID] == nil {
                            energyVenueManagers[venueID] = await EnergyVenueManager(venueID: venueID)
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("Clean Energy Charging is disabled", systemImage: "bolt.slash.fill")
                    } description: {
                        Text("Enable Clean Energy Charging to view venue details.")
                    }
                }
            }
        }
        .task {
            await loadVenues()
        }
        .alert("Alert", isPresented: $showAlert) {
            EnergyKitErrorView(error: energyKitError)
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadVenues() async {
        do {
            let venues = try await EnergyVenue.venues()
            for venue in venues {
                // Check if a charging location with this venue ID already exists
                let existingLocation = chargingLocations.first { $0.energyVenueID == venue.id }
                
                if existingLocation == nil {
                    modelContext.insert(ChargingLocation(energyVenueName: venue.name, energyVenueID: venue.id))
                }
            }
        } catch EnergyKitError.permissionDenied {
            energyKitError = .permissionDenied
            showAlert = true
        } catch EnergyKitError.locationServicesDenied {
            energyKitError = .locationServicesDenied
            showAlert = true
        } catch EnergyKitError.venueUnavailable {
            energyKitError = .venueUnavailable
        } catch {
            print("Failed to load venues: \(error)")
        }
    }

    private func deleteAllChargingLocations(at offsets: IndexSet) {
        withAnimation {
            offsets.map { chargingLocations[$0] }.forEach(deleteChargingLocation)
        }
    }

    private func deleteChargingLocation(_ chargingLocation: ChargingLocation) {
        // Unselect the item before deleting it.
        if chargingLocation.persistentModelID == selection?.persistentModelID {
            selection = nil
        }
        modelContext.delete(chargingLocation)
    }
    
    // MARK: Alert View Helper Functions
    private var alertMessage: String {
        switch energyKitError {
        case .permissionDenied:
            "Enable access to Energy Data."
        case .locationServicesDenied:
            EnergyKitError.locationServicesDenied.helpAnchor ?? "To use energy features with this app, you'll first need to turn on Location Services for the Home app and Home accessories. You can turn on Location Services for Home in Privacy & Security settings and for home accessories in System Services settings."
        default:
            "Please try again later."
        }
    }
}
