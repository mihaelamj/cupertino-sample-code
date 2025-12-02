/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI

struct LandmarksGrid: View {
    @Binding var landmarks: [Landmark]
    @State var isShowingLandmarksSelection: Bool = false

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: Constants.landmarkGridSpacing) {
                ForEach(landmarks, id: \.id) { landmark in
                    NavigationLink(value: landmark) {
                        LandmarkGridItemView(landmark: landmark)
                    }
                }
            }
        }
    }
    
    private var columns: [GridItem] {
        [ GridItem(.adaptive(minimum: Constants.landmarkGridItemMinSize,
                             maximum: Constants.landmarkGridItemMaxSize),
                   spacing: Constants.landmarkGridSpacing) ]
    }
}

#Preview {
    let modelData = ModelData()
    let previewCollection = modelData.userCollections[2]

    LandmarksGrid(landmarks: .constant(previewCollection.landmarks))
}
