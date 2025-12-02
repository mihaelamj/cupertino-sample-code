/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that displays a composition using a player view controller, and
synchronizes playback of the composition with a debug view.
*/

import Foundation
import AVFoundation
import AVKit
import UIKit

class PlayerViewController: UIViewController {
    // MARK: - Class Properties

    /// A view that displays content from a player and presents a native user interface to control playback.
    private var playerViewController = AVPlayerViewController()

    /// An instance of AVPlayer to use for movie playback.
    private var player = AVPlayer()

    /**
    An instance of AVPlayerItem to use to represent the presentation state of the asset that the AVPlayer plays.
    */
    private var playerItem: AVPlayerItem! {
        didSet {
            // Replace the current player item with the new item.
            player.replaceCurrentItem(with: playerItem)
        }
    }

    /// A SimpleEditor object instance to use to build a composition from the clips.
    private var editor: SimpleEditor!
        
    /**
     An instance of a debug view that represents the composition, video composition, and audio mix objects
     in a diagram.
    */
    @IBOutlet weak var compositionDebugView: CompositionDebugView!
        
    @IBOutlet weak var playerView: UIView!
    
    // MARK: - View Controller
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create a simple editor.
        self.editor = SimpleEditor(completion: {
            // Create a player item from the simple editor composition.
            self.playerItem = AVPlayerItem(asset: self.editor.composition())
            /*
             Set the player item's video composition and audio mix playback
             settings from the corresponding values in the simple editor.
            */
            self.playerItem.videoComposition = self.editor.videoComposition()
            self.playerItem.audioMix = self.editor.audioMix()

            // Set the player item on the debug view to synchronize playback.
            self.compositionDebugView.synchronize(with: self.playerItem)
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        /*
         Specify the player object that provides the media content for the view
         controller to display.
        */
        playerViewController.player = player
        /*
         Size the player view controller to match the player view in the actual
         scene.
        */
        playerViewController.view.frame = playerView.bounds

        /*
         Add the player view controller as a subview of the current view
         controller.
        */
        addChild(playerViewController)
        /*
         Add the player view controller as a subview of the current view
         controller so that it appears on top of any other subviews.
        */
        playerView.addSubview(playerViewController.view)
        /*
         Tell the subview controller that the animated transition for adding a
         new view to the view hierarchy is complete.
        */
        playerViewController.didMove(toParent: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        player.pause()
        super.viewWillDisappear(animated)
    }
}
