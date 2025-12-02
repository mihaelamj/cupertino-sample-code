/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that scrolls a list of landmarks horizontally.
*/

import SwiftUI

/// A view that scrolls a list of landmarks horizontally.
struct LandmarkHorizontalListView: View {
    let landmarkList: [Landmark]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Constants.standardPadding) {
                Spacer()
                    .frame(width: Constants.standardPadding)
                ForEach(landmarkList) { landmark in
                    NavigationLink(value: landmark) {
                        LandmarkListItemView(landmark: landmark)
                            .aspectRatio(Constants.landmarkListItemAspectRatio, contentMode: .fill)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    let modelData = ModelData()

    LandmarkHorizontalListView(landmarkList: modelData.landmarks)
        .frame(height: 180.0)
}
