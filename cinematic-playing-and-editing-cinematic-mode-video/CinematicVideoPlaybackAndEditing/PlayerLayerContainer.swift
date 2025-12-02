/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A `PlayerLayerView` container.
*/

import SwiftUI
import AVFoundation

struct PlayerLayerContainer: ViewRepresentable {
    typealias ViewType = PlayerLayerView

    let player: AVPlayer

    @Binding var videoRect: CGRect

    func makeView(context: Context) -> PlayerLayerView {

#if os(iOS)
        let view = PlayerLayerView()
#elseif os(macOS)
        let view = PlayerLayerView(frame: .zero)
#endif

        view.playerLayer.publisher(for: \.videoRect).receive(on: DispatchQueue.main).sink { newValue in
            self.videoRect = newValue
        }.store(in: &view.cancellables)

        return view
    }

    func updateView(_ view: PlayerLayerView, context: Context) {
        view.playerLayer.player = player
    }
}
