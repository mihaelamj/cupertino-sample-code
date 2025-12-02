/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A modally presented view displaying a grid of stickers to export,
  if available; otherwise, a progress indicator.
*/

import SwiftUI

struct StickerGrid: View {
    let viewModel: StickerViewModel
    @State private var finishedLoading: Bool = false

    var body: some View {
        NavigationStack {
            VStack {
                if finishedLoading {
                    GridContent(viewModel: viewModel)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                }
            }
            .configureStickerGrid()
        }
    }
}
