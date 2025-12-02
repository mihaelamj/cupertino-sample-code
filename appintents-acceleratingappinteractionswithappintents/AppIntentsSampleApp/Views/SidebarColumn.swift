/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The sidebar column for the app.
*/

import SwiftUI
import AppIntents

/// The sidebar column for the app, containing user info, trail collections, and a view that opens the Shortcuts app.
struct SidebarColumn: View {
    
    @Environment(TrailDataManager.self) private var trailManager
    @Environment(NavigationModel.self) private var navigationModel
    @Environment(ActivityTracker.self) private var activityTracker
    
    var body: some View {
        @Bindable var navigationModel = navigationModel
        List(selection: $navigationModel.selectedCollection) {
            AuthenticationItem()
            
            if activityTracker.activityInProgress != nil {
                Button(action: {
                    navigationModel.displayInProgressActivityInfo = true
                }) {
                    Label("Tracking an Activity", systemImage: "shoeprints.fill")
                }.buttonStyle(.plain)
            }
            
            Section("For You") {
                ForEach(trailManager.forYouCollections) { collection in
                    NavigationLink(value: collection) {
                        Label(collection.name, systemImage: collection.symbolName)
                    }
                }
            }
            Section("Featured Locations") {
                ForEach(trailManager.featuredTrailCollections) { collection in
                    NavigationLink(value: collection) {
                        Label(collection.name, systemImage: collection.symbolName)
                    }
                }
            }
            
        #if os(iOS) || os(visionOS)
            HStack {
                Spacer()
                
                /// `ShortcutsLink` opens this app's page in the Shortcuts app, so the user can see all of the App Shortcuts the app provides.
                ShortcutsLink()
                    .shortcutsLinkStyle(.automatic)
                
                Spacer()
            }
        #endif
        }
        .navigationTitle("Trail Collections")
    }
}
