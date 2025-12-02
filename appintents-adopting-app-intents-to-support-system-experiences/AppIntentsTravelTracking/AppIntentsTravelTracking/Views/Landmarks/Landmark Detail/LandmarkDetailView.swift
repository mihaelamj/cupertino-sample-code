/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI
import MapKit
import AppIntents

struct LandmarkDetailView: View {
    @Environment(ModelData.self) var modelData
    let landmark: Landmark
    var landmarkEntity: LandmarkEntity { LandmarkEntity(landmark: landmark, modelData: modelData) }
    @State private var inspectorIsPresented = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: Constants.standardPadding) {
                    Image(landmark.backgroundImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width,
                               height: geometry.size.height / 2)
                        .backgroundExtensionEffect()
                    .padding(.leading, -Constants.matchesNavigationTitlePadding)
                    .padding(.top, -geometry.safeAreaInsets.top)
                    .overlay(alignment: .bottomTrailing) {
                        VStack(alignment: .trailing) {
                            Text("Occupancy: \(modelData.getCrowdStatus(landmarkID: landmark.id))%")
                            HStack(spacing: 2) {
                                Image(systemName: "sun.min.fill")
                                    .foregroundStyle(.yellow)
                                Text("Sunny 98°F")
                            }
                        }
                        .padding(8)
                        .font(.headline)
                        .background(.thinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(8)
                    }

                    HStack(alignment: .bottom) {
                        Text(landmark.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .userActivity(
                                "com.landmarks.ViewingLandmark"
                            ) {
                                $0.title = "Viewing \(landmark.name)"
                                $0.appEntityIdentifier = EntityIdentifier(for: try! modelData.landmarkEntity(id: landmark.id))
                            }
                    }
                    Text(landmark.description)
                        .textSelection(.enabled)
                        .font(.body)
                        .padding(.trailing, Constants.matchesNavigationTitlePadding * 2)
                }
                .padding(.leading, Constants.matchesNavigationTitlePadding)
            }
        }
        .inspector(isPresented: $inspectorIsPresented) {
            LandmarkDetailInspectorView(landmark: landmark, inspectorIsPresented: $inspectorIsPresented)
        }
        .toolbar {
            ToolbarItem {
                ShareLink(item: landmarkEntity, preview: landmarkEntity.sharePreview)
            }

            ToolbarSpacer(.fixed)

            ToolbarItemGroup {
                Button {
                    let isFavorite = modelData.isFavorite(landmark)
                    if isFavorite {
                        modelData.removeFavorite(landmark)
                    } else {
                        modelData.addFavorite(landmark)
                    }
                } label: {
                    let isFavorite = modelData.isFavorite(landmark)
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                }

                LandmarkCollectionsMenu(landmark: landmark)
            }
            
            ToolbarSpacer(.fixed)

            ToolbarItemGroup {
                Button {
                    inspectorIsPresented.toggle()
                } label: {
                    Image(systemName: "info")
                }
            }
        }
        .userActivity("com.landmarks.ViewingLandmark") { activity in
            activity.title = "Viewing \(landmark.name)"
            activity.appEntityIdentifier = EntityIdentifier(
                for: LandmarkEntity.self, identifier: landmark.id
            )
        }
    }
}

struct LandmarkCollectionsMenu: View {
    @Environment(ModelData.self) private var modelData
    let landmark: Landmark

    var body: some View {
        Menu("Collections", systemImage: "book.closed") {
            ForEach(modelData.userCollections) {
                @Bindable var collection = $0
                Toggle(collection.name, isOn: $collection[contains: landmark])
            }
        }
        .menuIndicator(.hidden)
    }
}

private extension LandmarkDetailView {
    func scrollToCrowdStatus() {

    }
}

#Preview {
    let modelData = ModelData()
    let previewLandmark = modelData.landmarksById[1005] ?? modelData.landmarks.first!

    LandmarkDetailView(landmark: previewLandmark)
        .environment(modelData)
}
