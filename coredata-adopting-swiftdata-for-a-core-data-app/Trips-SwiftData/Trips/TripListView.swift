/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the trip list.
*/

import SwiftUI
import SwiftData
import WidgetKit

struct TripListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Trip.startDate, order: .forward)
    var trips: [Trip]

    @Binding var selection: Trip?
    @Binding var tripCount: Int
    @Binding var unreadTripIdentifiers: [PersistentIdentifier]

    init(selection: Binding<Trip?>, segment: Binding<ContentView.Segment>, tripCount: Binding<Int>,
         unreadTripIdentifiers: Binding<[PersistentIdentifier]>,
         searchText: String) {
        _selection = selection
        _tripCount = tripCount
        _unreadTripIdentifiers = unreadTripIdentifiers
        let searchPredicate = #Predicate<Trip> {
            searchText.isEmpty ? true : $0.name.localizedStandardContains(searchText) || $0.destination.localizedStandardContains(searchText)
        }
        let classPredicate: Predicate<Trip>? = {
            switch segment.wrappedValue {
            case .all:
                return nil
            case .personal:
                return #Predicate { $0 is PersonalTrip }
            case .business:
                return #Predicate { $0 is BusinessTrip }
            }
        }()
        let fullPredicate: Predicate<Trip>
        if let classPredicate {
            fullPredicate = #Predicate { classPredicate.evaluate($0) && searchPredicate.evaluate($0) }
        } else {
            fullPredicate = searchPredicate
        }

        _trips = Query(filter: fullPredicate, sort: \.startDate, order: .forward)
    }

    var body: some View {
        List(selection: $selection) {
            ForEach(trips) { trip in
                TripListItem(trip: trip, isUnread: unreadTripIdentifiers.contains(trip.persistentModelID))
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteTrip(trip)
                            WidgetCenter.shared.reloadTimelines(ofKind: "TripsWidget")
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
            .onDelete(perform: deleteTrips(at:))
        }
        .overlay {
            if trips.isEmpty {
                ContentUnavailableView {
                     Label("No Trips", systemImage: "car.circle")
                } description: {
                     Text("New trips you create will appear here.")
                }
            }
        }
        .navigationTitle("Upcoming Trips")
        .onChange(of: trips) {
            tripCount = trips.count
        }
        .onAppear {
            tripCount = trips.count
        }
    }
}

extension TripListView {
    private func deleteTrips(at offsets: IndexSet) {
        withAnimation {
            offsets.map { trips[$0] }.forEach { trip in
                deleteTrip(trip)
            }
        }
    }
    
    private func deleteTrip(_ trip: Trip) {
        /**
         Unselect the item before deleting it.
         */
        if trip.persistentModelID == selection?.persistentModelID {
            selection = nil
        }
        modelContext.delete(trip)
    }
}
