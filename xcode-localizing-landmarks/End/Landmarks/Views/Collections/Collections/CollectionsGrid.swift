/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a grid of landmark collections.
*/

import SwiftUI

/// A view that shows a grid of landmark collections.
struct CollectionsGrid: View {
    @Environment(ModelData.self) var modelData
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: Constants.collectionGridSpacing) {
                ForEach(modelData.userCollections, id: \.id) { collection in
                    NavigationLink(value: collection) {
                        CollectionListItemView(collection: collection)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.trailing, Constants.standardPadding)
    }
    
    private var columns: [GridItem] {
        [ GridItem(.adaptive(minimum: Constants.collectionGridItemMinSize,
                             maximum: Constants.collectionGridItemMaxSize),
                   spacing: Constants.collectionGridSpacing) ]
    }
}

#Preview {
    let modelData = ModelData()

    CollectionsGrid()
        .environment(modelData)
}
