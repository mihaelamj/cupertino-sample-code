/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A snippet view for a collection that appears in confirmation snippets.
*/

import SwiftUI

struct CollectionSnippetPreview: View {
    let name: String
    let description: String
    let landmarks: [Landmark]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.title.bold())

            Text(description)
                .foregroundStyle(.secondary)
                .font(.subheadline.bold())
                .lineLimit(3)

            Grid {
                GridRow {
                    ForEach(landmarks.prefix(4), id: \.self) { landmark in
                        VStack {
                            Image(landmark.thumbnailImageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            Text(landmark.name)
                                .lineLimit(1)
                                .font(.caption.bold())
                        }
                    }
                }
            }
            .padding(.vertical, 4)

            if landmarks.count > 4 {
                Text("and \(landmarks.count - 4) more...")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {

    let modelData = ModelData()

    CollectionSnippetPreview(
        name: "Romantic Viewpoints",
        description: "Take your special someone to these incredible places.",
        landmarks: modelData.landmarks
    )
        .padding(.horizontal, 10)
}
