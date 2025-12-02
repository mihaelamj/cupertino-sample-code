/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the main UI.
*/

import SwiftUI
import SwiftData
import WidgetKit

struct ContentView: View {
    enum Segment: String, CaseIterable {
        case all = "All"
        case personal = "Personal"
        case business = "Business"
    }
    @Environment(\.scenePhase) private var scenePhase
    @State private var showAddTrip = false
    @State private var selection: Trip?
    @State private var searchText: String = ""
    @State private var tripCount = 0
    @State private var unreadTripIdentifiers: [PersistentIdentifier] = []
    @State private var selectedSegment: Segment = .all
    @State private var newTripSegment: Segment = .all

    var body: some View {
        NavigationSplitView {
            TripListView(selection: $selection, segment: $selectedSegment, tripCount: $tripCount,
                         unreadTripIdentifiers: $unreadTripIdentifiers, searchText: searchText)
            .toolbar {
                toolbarItems
            }
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
            #endif
            
            #if os(macOS)
            tripSegmentPicker
                .padding(.bottom)
            #endif
        } detail: {
            if let selection = selection {
                NavigationStack {
                    TripDetailView(trip: selection)
                }
            }
        }
        .task {
            let tripIdentifiers = await DataModel.shared.unreadTripIdentifiersInUserDefaults
            unreadTripIdentifiers = tripIdentifiers
        }
        #if os(macOS)
        .searchable(text: $searchText, placement: .sidebar)
        #else
        .searchable(text: $searchText)
        .searchPresentationToolbarBehavior(.avoidHidingContent)
        #endif
        .sheet(isPresented: $showAddTrip) {
            NavigationStack {
                AddTripView(newTripSegment: $newTripSegment)
            }
            .presentationDetents([.medium, .large])
        }
        .onChange(of: selection) { _, newValue in
            if let newSelection = newValue {
                if let index = unreadTripIdentifiers.firstIndex(where: {
                    $0 == newSelection.persistentModelID
                }) {
                    unreadTripIdentifiers.remove(at: index)
                }
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            Task {
                if newValue == .active {
                    unreadTripIdentifiers += await DataModel.shared.findUnreadTripIdentifiers()
                } else {
                    // Persist the unread trip identifiers for the next launch session.
                    let tripIdentifiers = unreadTripIdentifiers
                    await DataModel.shared.setUnreadTripIdentifiersInUserDefaults(tripIdentifiers)
                }
            }
        }
        #if os(macOS)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            Task {
                unreadTripIdentifiers += await DataModel.shared.findUnreadTripIdentifiers()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            Task {
                let tripIdentifiers = unreadTripIdentifiers
                await DataModel.shared.setUnreadTripIdentifiersInUserDefaults(tripIdentifiers)
            }
        }
        #endif
    }
}

extension ContentView {
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if selectedSegment == .all {
                addTripMenu
            } else {
                addTripButton
            }
        }
        #if os(iOS)
        ToolbarItem(placement: .topBarLeading) {
            tripSegmentPicker
        }
        #endif
    }
    
    private var addTripMenu: some View {
        Menu("Add Trip", systemImage: "plus") {
            let segments: [Segment] = Segment.allCases.filter { $0 !=  .all }
            ForEach(segments, id: \.self) { segment in
                Button(segment.rawValue) {
                    newTripSegment = segment
                    showAddTrip = true
                }
            }
        }
    }
    
    private var addTripButton: some View {
        Button {
            newTripSegment = selectedSegment
            showAddTrip = true
        } label: {
            Label("Add trip", systemImage: "plus")
        }
    }
    
    private var tripSegmentPicker: some View {
        Picker("", selection: $selectedSegment) {
            ForEach(Segment.allCases, id: \.self) {
                Text($0.rawValue)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 250)
        .onChange(of: selectedSegment) {
            newTripSegment = selectedSegment
        }
    }
}

#Preview(traits: .sampleData) {
    ContentView()
}
