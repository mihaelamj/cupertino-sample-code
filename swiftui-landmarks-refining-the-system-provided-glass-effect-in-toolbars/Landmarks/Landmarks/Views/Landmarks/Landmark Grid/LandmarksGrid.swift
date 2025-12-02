/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a group of landmarks in a grid.
*/

import SwiftUI

/// A view that shows a group of landmarks in a grid.
struct LandmarksGrid: View {
    @Binding var landmarks: [Landmark]
    let forEditing: Bool

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Constants.landmarkGridSpacing) {
                ForEach(landmarks, id: \.id) { landmark in
                    if forEditing {
                        LandmarkGridItemView(landmark: landmark)
                    } else {
                        NavigationLink(destination: LandmarkDetailView(landmark: landmark)) {
                            LandmarkGridItemView(landmark: landmark)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    private var columns: [GridItem] {
        if forEditing {
            return [ GridItem(.adaptive(minimum: Constants.landmarkGridItemEditingMinSize,
                                        maximum: Constants.landmarkGridItemEditingMaxSize),
                              spacing: Constants.landmarkGridSpacing) ]
        }
        return [ GridItem(.adaptive(minimum: Constants.landmarkGridItemMinSize,
                                    maximum: Constants.landmarkGridItemMaxSize),
                          spacing: Constants.landmarkGridSpacing) ]
    }
}

#Preview {
    let modelData = ModelData()
    let previewCollection = modelData.userCollections[2]

    LandmarksGrid(landmarks: .constant(previewCollection.landmarks), forEditing: true)
}
