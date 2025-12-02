/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view backed by an `AVPlayerLayer`.
*/

import AVFoundation
import Combine

final class PlayerLayerView: PlatformView {

    var cancellables: [AnyCancellable] = []

    @objc var playerLayer: AVPlayerLayer {
        guard let playerLayer = layer as? AVPlayerLayer else {
            fatalError("Unexpected layer type")
        }
        
        return playerLayer
    }

#if os(iOS)
    override static var layerClass: AnyClass { AVPlayerLayer.self }
#elseif os(macOS)
    override init(frame: CGRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer = AVPlayerLayer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
#endif
}
