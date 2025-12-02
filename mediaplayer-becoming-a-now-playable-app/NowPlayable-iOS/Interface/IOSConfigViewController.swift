/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`IOSConfigViewController` shows the configuration being used by the player.
*/

import UIKit
import AVFoundation

class IOSConfigViewController: UIViewController {
    
    // The asset player controlling playback.
    
    var assetPlayer: AssetPlayer!
    
    // The player view.
    
    @IBOutlet weak var assetPlayerView: AssetPlayerView!
    
    // Set up the view controller initially.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateConfig()
    }
    
    // Update the UI when the data model is initialized.
    
    func updateConfig() {
        
        guard let tableViewController = children.first as? IOSConfigTableViewController else { return }
        
        tableViewController.updateConfig()
    }
    
    // MARK: Actions
    
    // Action method: opt into now-playability for the app.

    @IBAction func optIn(_ sender: Any?) {
        
        guard assetPlayer == nil else { return }
        
        // Create the asset player, if possible.
        
        do {
            assetPlayer = try AssetPlayer()
            assetPlayerView.player = assetPlayer.player
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
    }
    
}
