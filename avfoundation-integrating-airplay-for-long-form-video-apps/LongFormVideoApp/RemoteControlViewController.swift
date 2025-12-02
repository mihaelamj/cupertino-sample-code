/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A remote control view controller.
*/

import UIKit
import AVFoundation

class RemoteControlViewController: UIViewController {
	
	// MARK: Properties
	
	@IBOutlet weak var skipBack30Button: UIButton!
	@IBOutlet weak var playPauseButton: UIButton!
	@IBOutlet weak var skipAhead30Button: UIButton!
	var player: AVPlayer?
	
	// MARK: Actions
	
	@IBAction func skipBack30ButtonPressed(_ sender: UIButton) {
		guard let duration = player?.currentItem?.duration else { return }
		let targetTime = max(.zero, player!.currentTime() - CMTime(seconds: 30, preferredTimescale: duration.timescale))
		player?.seek(to: targetTime)
	}
	
	@IBAction func playPauseButtonPressed(_ sender: UIButton) {
		playPauseButton.isSelected = !playPauseButton.isSelected
		playPauseButton.isSelected ? player?.play() : player?.pause()
	}
	
	@IBAction func skipAhead30ButtonPressed(_ sender: UIButton) {
		guard let duration = player?.currentItem?.duration else { return }
		let targetTime = min(duration, player!.currentTime() + CMTime(seconds: 30, preferredTimescale: duration.timescale))
		player?.seek(to: targetTime)
	}
	
	// MARK: UIViewController
	
	override func viewDidLoad() {
        super.viewDidLoad()
		playPauseButton.isSelected = (player?.rate != 0)
	}
}

