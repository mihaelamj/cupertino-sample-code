/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom layout that places the `SpatialCarousel` subviews in a radial shape.
*/

import SwiftUI
import RealityKit

struct HikeDetailView: View {
    @Environment(AppModel.self) var appModel
    @Environment(\.dismiss) var dismissPopover

    let hike: Hike

    var labelText: String {
        if let selectedHike = appModel.selectedHike {
            return "Deselect \(selectedHike.name)"
        } else {
            return "Hike This Trail"
        }
    }

    var body: some View {
        PopoverView(
            title: hike.name,
            imageName: hike.featuredImageName,
            description: hike.description
        ) {
            Button {
                appModel.selectedHike = appModel.selectedHike == nil ? hike : nil
                dismissPopover()
            } label: {
                Text(labelText)
            }
            // Disable the hike button if there's no selected hike and no trail for the trailhead.
            .disabled(appModel.selectedHike == nil && hike.trailEntityPath == "")
        }
    }
}
