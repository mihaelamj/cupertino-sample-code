/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI

struct LandmarkFeaturedItemView: View {
    let landmark: Landmark

    var body: some View {
        NavigationLink(value: landmark) {
            Image(decorative: landmark.backgroundImageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .backgroundExtensionEffect()
                .overlay(alignment: .bottom) {
                    VStack {
                        Text("Featured Landmark", comment: "Big headline in the main image of featured landmarks.")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(0.8)
                        Text(landmark.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Button("Learn More") { }
                            .allowsHitTesting(false)
                            .buttonStyle(.borderedProminent)
                            .padding(.bottom, Constants.learnMorePadding)
                    }
                    .padding([.bottom], Constants.learnMoreBottomPadding)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let modelData = ModelData()
    let previewLandmark = modelData.landmarksById[1012] ?? modelData.landmarks.first!

    LandmarkFeaturedItemView(landmark: previewLandmark)
            .frame(height: 400.0)
}
