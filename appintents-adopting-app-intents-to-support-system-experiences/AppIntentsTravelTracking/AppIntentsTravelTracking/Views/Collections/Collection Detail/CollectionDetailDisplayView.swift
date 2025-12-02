/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI

struct CollectionDetailDisplayView: View {
    @Bindable var collection: Collection
    
    var body: some View {
        VStack() {
            HStack {
                Text(collection.name)
                    .font(.largeTitle)
                    .padding([.top, .leading, .trailing])
                Spacer()
            }
            HStack {
                Text(collection.description)
                    .font(.caption)
                    .padding([.bottom, .leading, .trailing])
                Spacer()
            }
            Divider()
                .padding([.leading, .trailing])
            LandmarksGrid(landmarks: $collection.landmarks)
                .padding([.leading, .trailing, .bottom])
        }
        .background(
            RoundedRectangle(cornerRadius: Constants.cornerRadius)
                .foregroundStyle(.white)
        )
        .frame(minWidth: Constants.collectionFormMinWidth,
               idealWidth: Constants.collectionFormIdealWidth,
               maxWidth: Constants.collectionFormMaxWidth)
        .padding()
    }
}

#Preview {
    let modelData = ModelData()
    let previewCollection = modelData.userCollections.last!

    CollectionDetailDisplayView(collection: previewCollection)
}
