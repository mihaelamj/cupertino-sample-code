/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that represents a video to play.
*/
import SwiftUI

struct VideoCard: View {

    let video: Video
    @Environment(PlayerModel.self) private var model

    private let cornerRadius = 20.0

    var body: some View {
        Button {
            model.playVideo(video)
        } label: {
            VStack {
                Image(video.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 210)
                VStack(alignment: .leading) {
                    Text(video.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(video.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                .padding()
            }
            .background(.thinMaterial)
            .cornerRadius(cornerRadius)
        }
        .buttonStyle(.plain)
        .buttonBorderShape(.roundedRectangle(radius: cornerRadius))
        .frame(width: 380, height: 300)
    }
}
