/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that plays the input video.
*/

import AVKit
import SwiftUI

struct PlayerView: UIViewRepresentable {
    let url: URL
    let isInverted: Bool

    private static let transparentPixelBufferAttributes = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

    class Coordinator {
        var playerLooper: AVPlayerLooper?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        let playerItem = AVPlayerItem(url: url)

        applyVideoComposition(for: playerItem)

        let player = AVQueuePlayer(playerItem: playerItem)
        player.actionAtItemEnd = .pause
        playerView.player = player

        if let playerLayer = playerView.playerLayer {
            playerLayer.videoGravity = .resizeAspect
            playerLayer.pixelBufferAttributes = Self.transparentPixelBufferAttributes
        }

        return playerView
    }

    func updateUIView(_ playerView: AVPlayerView, context: Context) {
        let currentItemUrl: URL? = (playerView.player?.currentItem?.asset as? AVURLAsset)?.url
        if currentItemUrl != url {
            let playerItem = AVPlayerItem(url: url)

            applyVideoComposition(for: playerItem)

            playerView.player?.replaceCurrentItem(with: playerItem)
        }
        playerView.player?.play()
    }

    private func applyVideoComposition(for playerItem: AVPlayerItem) {
        AVMutableVideoComposition.videoComposition(with: playerItem.asset, applyingCIFiltersWithHandler: { request in
            guard let filter = CIFilter(name: "CIMaskToAlpha") else {
                return
            }

            // Use the same image to mask the alpha.
            filter.setValue(request.sourceImage, forKey: kCIInputImageKey)

            guard let outputImage = filter.outputImage else {
                return
            }

            if isInverted {
                let invertFilterImage = outputImage.applyingFilter("CIColorInvert")
                return request.finish(with: invertFilterImage, context: nil)
            }

            return request.finish(with: outputImage, context: nil)
        }, completionHandler: { composition, error in
            playerItem.asset.loadTracks(withMediaType: .video) { tracks, error in
                Task {
                    if let tracks {
                        var videoSize: CGSize?

                        for track in tracks {
                            let naturalSize = try await track.load(.naturalSize)
                            let preferredTransform = try await track.load(.preferredTransform)

                            videoSize = !tracks.isEmpty ? naturalSize.applying(preferredTransform) : nil
                        }

                        if let composition,
                           let videoSize {
                            composition.renderSize = videoSize
                            playerItem.videoComposition = composition
                        }
                    }
                }
            }
        })
    }
}

class AVPlayerView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer? {
        layer as? AVPlayerLayer
    }

    var player: AVPlayer? {
        get { playerLayer?.player }
        set { playerLayer?.player = newValue }
    }
}
