/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main app, which creates a scene containing a window group
  that displays a horizontally scrolling carousel of stickers with data
  that the sticker data model populates.
*/

import SwiftUI

@main
struct SwiftStickerApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                PhotoPickerView(
                    viewModel: StickerViewModel()
                )
            }
        }
    }
}
