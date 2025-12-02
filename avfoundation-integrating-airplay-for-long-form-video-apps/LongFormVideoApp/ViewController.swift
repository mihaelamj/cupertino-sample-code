/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view controller.
*/

import UIKit
import AVKit

class ViewController: UIViewController {
	
	// MARK: Properties
	@IBOutlet weak var playVideoButton: UIButton!
	
	// MARK: Actions
	@IBAction func playVideoButtonPressed(_ sender: UIButton) {
		AVAudioSession.sharedInstance().prepareRouteSelectionForPlayback(completionHandler: { (shouldStartPlayback, routeSelection) in
			if shouldStartPlayback {
				switch routeSelection {
				case .local:
					print("Play locally")
					let playerViewController = AVPlayerViewController()
					if let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8") {
						do {
							try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
						} catch {
							print("Error setting audio session category and mode: \(error)")
						}
						let player = AVPlayer(url: url)
						playerViewController.player = player
						self.present(playerViewController, animated: true, completion: nil)
						player.play()
					}
				case .external:
					print("Play externally")
					if let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8") {
						do {
							try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
						} catch {
							print("Error setting audio session category and mode: \(error)")
						}
						let player = AVPlayer(url: url)
						let storyboard = UIStoryboard(name: "Main", bundle: nil)
						let identifier = "RemoteControlViewControllerID"
						if let remoteControlVC = storyboard.instantiateViewController(withIdentifier: identifier) as? RemoteControlViewController {
							remoteControlVC.player = player
							self.present(remoteControlVC, animated: true, completion: nil)
							player.play()
						}
					}
				case .none:
					fallthrough
				@unknown default:
					print("Cancelling playback")
				}
			} else {
				print("Cancelling playback")
			}
		})
	}
}

