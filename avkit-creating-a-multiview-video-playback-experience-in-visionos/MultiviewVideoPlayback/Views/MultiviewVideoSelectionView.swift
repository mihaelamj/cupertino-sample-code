/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The scrolling selection view for selecting a video.
*/

import AVKit
import SwiftUI

struct MultiviewVideoSelectionView: View {
    let multiviewStateModel: MultiviewStateModel
    let fromMultiviewContentSelection: Bool

    func overlaySystemIconName(for videoModel: VideoModel) -> String? {
        guard fromMultiviewContentSelection else { return nil }

        return videoModel.isAddedToMultiview ? "checkmark.circle.fill" : "plus.circle"
    }

    var body: some View {
        ScrollView([.horizontal]) {
            HStack(spacing: 28.0) {
                ForEach(multiviewStateModel.videoModels, id: \.video) { videoModel in
                    Button {
                        Task {
                            await multiviewStateModel.videoSelected(
                                videoModel: videoModel,
                                inMultiview: fromMultiviewContentSelection
                            )
                        }
                    } label: {
                        VideoItemSelectionView(
                            videoModel: videoModel,
                            inMultiviewContentSelection: fromMultiviewContentSelection
                        )
                        .padding(.vertical, 5)
                    }
                    .buttonBorderShape(.roundedRectangle(radius: 25.0))
                }
            }
            .padding(20)
        }
        .scrollIndicators(.hidden)
        .padding(.leading, 5.0)
        .frame(minHeight: 320.0)
    }
}
