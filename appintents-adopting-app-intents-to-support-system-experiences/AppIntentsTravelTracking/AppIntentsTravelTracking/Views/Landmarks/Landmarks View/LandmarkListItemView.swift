/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI

struct LandmarkListItemView: View {
    let landmark: Landmark

    var body: some View {
        GeometryReader { geometry in
            Image(landmark.thumbnailImageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .overlay {
                    ReadabilityRoundedRectangle()
                }
                .clipped()
                .cornerRadius(Constants.cornerRadius)
                .overlay(alignment: .bottom) {
                    Text(landmark.name)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.bottom)
                }
        }
    }
}

#Preview {
    let modelData = ModelData()
    let previewLandmark = modelData.landmarksById[1001] ?? modelData.landmarks.first!
    LandmarkListItemView(landmark: previewLandmark)
        .frame(width: 252.0, height: 180.0)
}
