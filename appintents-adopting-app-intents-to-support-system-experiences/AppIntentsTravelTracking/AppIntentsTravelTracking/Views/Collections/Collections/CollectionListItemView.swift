/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI

struct CollectionListItemView: View {
    let collection: Collection
    
    var body: some View {
        VStack {
            collection.imageForListItem()
                .cornerRadius(Constants.cornerRadius)
            Text(collection.name)
            Text("\(collection.landmarks.count) items")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let modelData = ModelData()
    let previewCollection = modelData.userCollections.first!

    CollectionListItemView(collection: previewCollection)
}
