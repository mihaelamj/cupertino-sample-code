/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Sprite Kit tool that plays back an alpha based video over a background scene.
*/

import Cocoa
import SpriteKit
import AVFoundation

class ViewController: NSViewController {
    
    @IBOutlet var skView: SKView!
    var videoPlayer: AVPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.skView {
            // Load the SKScene from 'backgroundScene.sks'
            guard let scene = SKScene(fileNamed: "backgroundScene") else {
                print("Could not create a background scene")
                return
            }
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFill
            // Present the scene
            view.presentScene(scene)
            
            // Add the video node
            guard let alphaMovieURL = Bundle.main.url(forResource: "puppets_with_alpha_hevc", withExtension: "mov") else {
                print("Failed to overlay alpha movie on the background")
                return
            }
            videoPlayer = AVPlayer(url: alphaMovieURL)
            let video = SKVideoNode(avPlayer: videoPlayer)
            video.size = CGSize(width: view.frame.width, height: view.frame.height)
            print( "Video size is %f x %f", video.size.width, video.size.height)
            scene.addChild(video)
            
            // Play video
            videoPlayer.play()
        }
    }
}

