/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The thumbnail film strip view for navigating multiple images.
*/

import Foundation
import SwiftUI

struct FilmStrip: View {

    @Binding var assets: [Asset]
    @Binding var selectedAsset: Asset?

    var body: some View {
        GeometryReader { geometry  in
            let size = min(geometry.size.width, geometry.size.height) - 8.0
            ScrollView(.horizontal) {
                LazyHStack(spacing: 4.0) {
                    ForEach(assets) { asset in
                        Button {
                            self.selectedAsset = asset
                        } label: {
                            Group {
                                // Show a thumbnail if one is available. Otherwise, show a default image.
                                if let thumbnail = asset.thumbnail {
                                    Image(thumbnail, scale: 1.0, label: Text(asset.name))
                                        .resizable()
                                } else {
                                    Image(systemName: "photo")
                                        .resizable()
                                }
                            }
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size, height: size)
                            .clipped()
                            .background(alignment: .center) {
                                if asset == self.selectedAsset {
                                    Color.accentColor
                                        .padding(-4.0)
                                }
                            }

                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(4.0)
            }
        }
    }
}
