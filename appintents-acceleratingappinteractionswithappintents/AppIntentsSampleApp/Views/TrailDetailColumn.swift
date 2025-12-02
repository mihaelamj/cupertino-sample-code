/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the detailed description of the trail selected in the navigation model.
*/

import SwiftUI

struct TrailDetailColumn: View {
    @Environment(NavigationModel.self) private var navigationModel
    
    var body: some View {
        ZStack {
            if let trail = navigationModel.selectedTrail {
                TrailDetailView(trail: trail)
            } else {
                ContentUnavailableView("Select a Trail", systemImage: "shoeprints.fill", description: Text("Pick something from the list."))
            }
        }
    }
}
