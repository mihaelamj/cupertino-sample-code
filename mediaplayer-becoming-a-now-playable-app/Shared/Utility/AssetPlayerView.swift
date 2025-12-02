/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`AssetPlayerView` is a view backed by an AVPlayerLayer.
*/

import UIKit
import AVFoundation

class AssetPlayerView: UIView {
    
    // The player assigned to this view, if any.
    
    var player: AVPlayer? {
        get { return playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    // The layer used by the player.
    
    var playerLayer: AVPlayerLayer {
        
        guard let playerLayer = layer as? AVPlayerLayer
            else { fatalError("AssetPlayerView player layer must be an AVPlayerLayer") }
        
        return playerLayer
    }
    
    // Set the class of the layer for this view.
    
    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
}
