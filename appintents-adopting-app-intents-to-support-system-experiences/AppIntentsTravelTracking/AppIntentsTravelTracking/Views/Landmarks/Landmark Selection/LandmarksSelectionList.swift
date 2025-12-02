/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import SwiftUI

struct LandmarksSelectionList: View {
    @Environment(ModelData.self) var modelData
    @Binding var landmarks: [Landmark]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(ModelData.orderedContinents, id: \.self) { continent in
                    Section(header: Text(continent.rawValue)) {
                        ForEach(modelData.landmarksByContinent[continent] ?? []) { landmark in
                            LandmarksSectionListItem(landmark: landmark, landmarks: $landmarks)
                                .onTapGesture {
                                    if landmarks.contains(landmark) {
                                        if let landmarkIndex = landmarks.firstIndex(of: landmark) {
                                            landmarks.remove(at: landmarkIndex)
                                        }
                                    } else {
                                        landmarks.append(landmark)
                                    }
                                }
                        }
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationTitle("Select landmarks")
            .toolbar {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

#Preview {
    let modelData = ModelData()
    let previewCollection = modelData.userCollections.last!

    LandmarksSelectionList(landmarks: .constant(previewCollection.landmarks))
        .environment(modelData)
}
