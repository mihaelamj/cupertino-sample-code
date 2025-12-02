/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays a landmark in a snippet.
*/

import AppIntents
import SwiftUI

struct LandmarkView: View {
    let landmark: LandmarkEntity
    let isFavorite: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(landmark.landmark.backgroundImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 27))
                .clipShape(ContainerRelativeShape())
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(landmark.name)
                        .foregroundStyle(Color.primary)
                        .font(.largeTitle.bold())

                    Spacer()

                    Button(intent: UpdateFavoritesIntent(
                        landmark: landmark,
                        isFavorite: !isFavorite
                    )) { /* ... */
                        Image(systemName: "heart")
                            .symbolVariant(isFavorite ? .fill : .none)
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.red)
                    }
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                    .buttonStyle(ScaleButtonStyle())
                }

                Text(landmark.description)
                    .foregroundStyle(.secondary)
                    .font(.headline)
                    .lineLimit(3)

                Button(intent: FindTicketsIntent(landmark: landmark)) { /* ... */
                    Text("\(Image(systemName: "ticket.fill")) Find Best Ticket Prices \(Image(systemName: "chevron.right"))")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.accentColor)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
    }
}

#Preview {
    let modelData = ModelData()
    ScrollView {
        LandmarkView(
            landmark: LandmarkEntity(
                landmark: modelData.landmarksById[1005]!,
                modelData: modelData
            ),
            isFavorite: true
        )

        LandmarkView(
            landmark: LandmarkEntity(
                landmark: modelData.landmarksById[1005]!,
                modelData: modelData
            ),
            isFavorite: false
        )

        LandmarkView(
            landmark: LandmarkEntity(
                landmark: modelData.landmarksById[1001]!,
                modelData: modelData
            ),
            isFavorite: true
        )
    }
    .padding(10)
}
