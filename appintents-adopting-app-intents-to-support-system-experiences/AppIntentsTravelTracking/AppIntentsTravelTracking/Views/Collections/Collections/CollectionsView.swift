/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI

struct CollectionsView: View {
    @Environment(ModelData.self) var modelData
    @Environment(Navigator.self) var navigator

    var body: some View {
        @Bindable var navigator = navigator
        NavigationStack(path: $navigator.collectionNavigationPath) {
            ScrollView(.vertical) {
                LazyVStack {
                    HStack {
                        CollectionTitleView(title: "Favorites", comment: "Section title above favorite collections.")
                        Spacer()
                    }
                    .padding(.leading, Constants.leadingContentInset)

                    LandmarkHorizontalListView(landmarkList: modelData.favoritesCollection.landmarks)
                        .containerRelativeFrame(.vertical) { height, axis in
                            return height * Constants.landmarkListPercentOfHeight
                        }
                        .padding(.leading, -Constants.matchesNavigationTitlePadding)

                    HStack {
                        CollectionTitleView(title: "My Collections", comment: "Section title above the person's collections.")
                        Spacer()
                    }
                    .padding(.leading, Constants.leadingContentInset)

                    CollectionsGrid(collections: modelData.userCollections)
                }
                .padding(.leading, Constants.matchesNavigationTitlePadding)
            }
            .navigationTitle("Collections")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        modelData.addUserCollection()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(for: Collection.self) { collection in
                CollectionDetailView(collection: collection)
            }
            .navigationDestination(for: Landmark.self) { landmark in
                LandmarkDetailView(landmark: landmark)
            }
        }
    }
}

private struct CollectionTitleView: View {
    let title: LocalizedStringKey
    let comment: StaticString

    var body: some View {
        Text(title, comment: comment)
            .font(.title2)
            .bold()
            .padding(.top, Constants.titleTopPadding)
    }
}

#Preview {
    CollectionsView()
        .environment(ModelData())
}
