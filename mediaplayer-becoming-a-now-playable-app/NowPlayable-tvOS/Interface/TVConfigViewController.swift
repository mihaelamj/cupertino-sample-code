/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`TVConfigViewController` shows buttons to start and end NowPlayable opt-in.
*/

import UIKit
import AVFoundation

class TVConfigViewController: UIViewController {
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!

    // The asset player controlling playback.
    
    var assetPlayer: AssetPlayer!
    
    // A type-safe reference to the controller's player view.
    
    var assetPlayerView: AssetPlayerView {
        
        guard let playerView = view as? AssetPlayerView
            else { fatalError("TVConfigViewController view must be an AssetPlayerView") }
        
        return playerView
    }
    
    // A gesture recognizer for the Menu button on the remote control.
    
    var menuGestureRecognizer: UITapGestureRecognizer!
    
    // Set up the view controller initially.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(menuReturn(_:)))
        menuGestureRecognizer.allowedPressTypes = [UIPress.PressType.menu.rawValue as NSNumber]
    }
    
    // MARK: Actions
    
    // Action method: opt into now-playability for the app, and hide the buttons.
    
    @IBAction func optIn(_ sender: Any?) {
        
        guard assetPlayer == nil else { return }
        
        // Create the asset player, if possible.
        
        do {
            assetPlayer = try AssetPlayer()
            assetPlayerView.player = assetPlayer.player
            
            startButton.isHidden = true
            stopButton.isHidden = true
            view.addGestureRecognizer(menuGestureRecognizer)
        }
            
            // Otherwise, display an error.
            
        catch {
            let viewController = UIAlertController(title: "Player could not be created.", message: error.localizedDescription, preferredStyle: .alert)
            present(viewController, animated: true)
        }
    }
    
    // Action method: opt out of now-playability.
    
    @IBAction func optOut(_ sender: Any?) {
        
        guard assetPlayer != nil else { return }
        
        assetPlayer.optOut()
        assetPlayer = nil
        view.removeGestureRecognizer(menuGestureRecognizer)
    }
    
    // Action method: show the buttons again.
    
    @IBAction func menuReturn(_ sender: Any?) {
        
        startButton.isHidden = false
        stopButton.isHidden = false
    }
    
}

