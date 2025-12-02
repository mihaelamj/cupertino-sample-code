/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI

struct LandmarksNavigationStack: View {

    @Environment(Navigator.self) var navigator
    @State var isEditing: Bool = false

    var body: some View {
        @Bindable var navigator = navigator

        NavigationStack(path: $navigator.landmarkNavigationPath) { /* ... */
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: Constants.standardPadding) {

                    LandmarkFeaturedItemView(landmark: modelData.featuredLandmark!)
                        .frame(width: geometry.size.width,
                               height: geometry.size.height / 2)
                        .padding(.leading, -Constants.matchesNavigationTitlePadding)
                        .padding(.top, -geometry.safeAreaInsets.top)

                    ForEach(ModelData.orderedContinents, id: \.self) { continent in
                        Group {
                            Text(continent.rawValue)
                                .font(.title)
                                .bold()
                            if let landmarkList = modelData.landmarksByContinent[continent] {
                                LandmarkHorizontalListView(landmarkList: landmarkList)
                                    .containerRelativeFrame(.vertical) { height, axis in
                                        return height * Constants.landmarkListPercentOfHeight
                                    }
                                    .padding(.leading, -Constants.matchesNavigationTitlePadding)
                            }
                        }
                    }
                }
                .padding(.leading, Constants.matchesNavigationTitlePadding)
            }
        }
        .handlesExternalEvents(
            preferring: [],
            allowing: !isEditing ? [OpenLandmarkIntent.persistentIdentifier] : []
        )
        .navigationDestination(for: Landmark.self) { landmark in
            LandmarkDetailView(landmark: landmark)
        }
    }

    @Environment(ModelData.self) var modelData
    let geometry: GeometryProxy
}
