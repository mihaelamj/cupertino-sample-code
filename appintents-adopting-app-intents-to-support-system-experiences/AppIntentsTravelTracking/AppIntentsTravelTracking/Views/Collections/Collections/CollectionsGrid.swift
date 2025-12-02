/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI

struct CollectionsGrid: View {
    let collections: [Collection]
    
    var body: some View {
        ScrollView {
            ViewThatFits {
                collectionsGrid(with: 4)
                collectionsGrid(with: 3)
                collectionsGrid(with: 2)
            }
        }
        .padding(.trailing, Constants.standardPadding)
    }
    
    @MainActor @ViewBuilder private func collectionsGrid(with columns: Int) -> some View {
        
        let gridItem = GridItem(.flexible(minimum: Constants.collectionGridItemMinSize,
                                          maximum: Constants.collectionGridItemMaxSize),
                                spacing: Constants.collectionGridSpacing)

        let columns: [GridItem] = Array(repeating: gridItem, count: columns)
        
        LazyVGrid(columns: columns, alignment: .leading, spacing: Constants.collectionGridSpacing) {
            ForEach(collections, id: \.id) { collection in
                NavigationLink(value: collection) {
                    CollectionListItemView(collection: collection)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    let modelData = ModelData()

    CollectionsGrid(collections: modelData.userCollections)
}
