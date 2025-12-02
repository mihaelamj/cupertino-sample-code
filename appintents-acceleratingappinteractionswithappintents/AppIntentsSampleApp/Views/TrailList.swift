/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A list view that displays the trails in a collection.
*/

import SwiftUI
import AppIntents

struct TrailList: View {
    
    @Environment(TrailDataManager.self) private var trailManager
    @Environment(NavigationModel.self) private var navigationModel
    
    /// A binding to a user preference indicating whether they hide the Siri tip.
    @AppStorage("displaySiriTip") private var displaySiriTip: Bool = true
    
    /// - Tag: siri_tip
    var body: some View {
        ZStack {
            if let trailCollection = navigationModel.selectedCollection {
                @Bindable var navigationModel = navigationModel
                List(selection: $navigationModel.selectedTrail) {
                #if os(iOS) || os(visionOS)
                    if trailCollection.collectionType == .favorites {
                        /**
                         `SiriTipView` pairs with an intent the system uses as an App Shortcut. It provides a small view with the phrase from the
                         App Shortcut so that people learn they can view their favorite trails quickly by speaking the phrase to Siri with no
                         additional setup. The `isVisible` parameter is optional, but recommended to enable people to hide the view.
                         */
                        SiriTipView(intent: OpenFavorites(), isVisible: $displaySiriTip)
                    }
                #endif
                    
                    ForEach(trailManager.trails(with: trailCollection.members)) { trail in
                        NavigationLink(trail.name, value: trail)
                    }
                }
                .navigationTitle(trailCollection.name)
            } else {
                ContentUnavailableView("Select a Trail Collection",
                                       systemImage: "shoeprints.fill",
                                       description: Text("Pick something from the list."))
            }
        }
    }
}
