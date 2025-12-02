/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Contains the `DogModalView` class.
*/

import UIKit

/**
 This modal view displays a gallery of images for the dog, and has a dark transparent background so that
 you can still see the content of the view below it. It is meant to be a full screen modal view,
 but it creates problems for VoiceOver because it isn't a view controller that is presented modally.
 Because it's simply a view that's added on top of everything else, and because it has a transparent background so the
 views behind are still visible, VoiceOver doesn't inherently know that the views behind it should no longer
 be accessible. So the user can still swipe to access those views behind it while this view is presented.
 This creates a confusing, bad experience, so we override `accessibilityViewIsModal` to indicate
 this view and its contents are the only thing on screen VoiceOver should currently care about.
*/
class DogModalView: UIView {
    // MARK: Poperties

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var firstImageView: UIImageView!
    @IBOutlet weak var secondImageView: UIImageView!
    
    // MARK: Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        closeButton.layer.cornerRadius = closeButton.bounds.width / 2.0
        closeButton.layer.borderWidth = 1.0
        closeButton.layer.borderColor = UIColor.lightGray.cgColor
    }

    // MARK: IBActions

    @IBAction func closeButtonTapped(_ sender: Any) {
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 0.0
        }, completion: { finished in
            if finished {
                self.removeFromSuperview()
            }
        })
    }

    // MARK: Accessibility

    /// - Tag: is_modal
    override var accessibilityViewIsModal: Bool {
        get {
            return true
        }

        set {}
    }
}
