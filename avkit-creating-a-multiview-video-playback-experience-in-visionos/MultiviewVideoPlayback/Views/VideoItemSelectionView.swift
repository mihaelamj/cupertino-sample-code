/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The individual view for a video item.
*/

import SwiftUI

struct VideoItemSelectionView: View {
    let videoModel: VideoModel
    let inMultiviewContentSelection: Bool

    var overlaySystemIconName: String? {
        guard inMultiviewContentSelection else { return nil }

        return videoModel.isAddedToMultiview ? "checkmark.circle.fill" : "plus.circle"
    }

    var body: some View {
        ContentSelectionViewItem(
            overlaySystemIconName: overlaySystemIconName,
            url: videoModel.video.url,
            title: videoModel.video.title,
            subtitle: inMultiviewContentSelection ? videoModel.video.subtitle : videoModel.video.description,
            reservedLines: inMultiviewContentSelection ? 1 : 3
        )
    }
}

struct ContentSelectionViewItem: View {
    let overlaySystemIconName: String?
    let url: URL?
    let title: String
    let subtitle: String?
    let reservedLines: Int

    private let height: CGFloat = 130.0
    private var aspectRatio: CGFloat { 16.0 / 9 }
    private var width: CGFloat { aspectRatio * height }

    var body: some View {
        VStack(alignment: .leading) {
            if let url {
                ThumbnailView(url: url)
                    .aspectRatio(aspectRatio, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 15.0))
                    .frame(width: width, height: height)
                    .overlay(alignment: .bottomLeading) {
                        if let overlaySystemIconName {
                            Image(systemName: overlaySystemIconName)
                                .foregroundColor(.white)
                                .font(.system(size: 28.0))
                                .padding(8.0)
                        }
                    }
            }

            Text(title)
                .foregroundStyle(.primary)
                .padding(.top, 10.0)

            if let subtitle {
                Text(subtitle)
                    .foregroundStyle(.tertiary)
                    .lineLimit(reservedLines, reservesSpace: true)
            }
        }
        .frame(width: width)
        .lineLimit(1)
    }
}

#Preview {
    let item = defaultVideos.first!
    ContentSelectionViewItem(
        overlaySystemIconName: true ? "checkmark.circle.fill" : "plus.circle",
        url: item.url,
        title: item.title,
        subtitle: item.subtitle,
        reservedLines: 2
    )
    .border(.red.opacity(0.25))
    .padding(50)
    .glassBackgroundEffect()
}
