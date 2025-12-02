/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays an asset.
*/

import SwiftUI
import Photos
import AVKit

struct AssetView: View {

    @Binding var asset: CinematicAsset

    @State var exportOrScriptSaveInProgress: Bool = false

    var body: some View {
        TabView {
            CinematicPlayer(player: asset.player, fNumber: $asset.fNumber)
                .tabItem {
                    Text("Play")
                }
            CinematicEditor(asset: $asset,
                            exportOrSaveScriptInProgress: $exportOrScriptSaveInProgress)
                .tabItem {
                    Text("Edit")
                }
        }
        .disabled(exportOrScriptSaveInProgress)
    }
}
