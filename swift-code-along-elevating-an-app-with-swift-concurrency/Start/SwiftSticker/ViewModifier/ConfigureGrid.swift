/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view extension that provides configuration for a sheet displaying a grid
  of stickers.
*/

import SwiftUI

extension View {
    func configureStickerGrid() -> some View {
        modifier(ConfigureStickerGrid())
    }
}

private struct ConfigureStickerGrid: ViewModifier {
    @Environment(\.dismiss) var dismiss

    func body(content: Content) -> some View {
        content
            .background(Color.yellow.quinary)
            .navigationBarTitleDisplayMode(.large)
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .largeTitle) {
                    Text("Your Stickers")
                        .font(.system(.largeTitle, design: .serif, weight: .medium))
                }
            }
    }
}
