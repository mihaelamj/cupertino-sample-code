/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that represents immersive video content.
*/

import SwiftUI

struct VideoCard: View {
    private static let radius = CGFloat(12)
    private static let shape = RoundedRectangle(
        cornerSize: CGSize(width: Self.radius, height: Self.radius),
        style: .continuous
    )

    let model: VideoModel
    @Environment(AppModel.self) private var appModel

    var body: some View {
        Button {
            appModel.selectVideo(model)
        } label: {
            VStack(alignment: .leading) {
                ZStack {
                    model.background

                    if let imageName = model.imageName {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
                    }
                }
                .clipShape(Self.shape)

                Text(model.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(model.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding()
        }
        .buttonBorderShape(.roundedRectangle(radius: 18))
        .buttonStyle(.plain)
    }
}
