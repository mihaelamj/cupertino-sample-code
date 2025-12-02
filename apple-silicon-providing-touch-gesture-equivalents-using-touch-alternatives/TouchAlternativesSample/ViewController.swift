/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that displays a circle that moves with touch gestures.
*/

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet private var circle: UIImageView!
    private var startCircleLocation = CGPoint.zero
    private var startPanLocation = CGPoint.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        circle.center = view.center
        
        // Pan anywhere on the screen to move the circle.
        let pan = UIPanGestureRecognizer(target: self, action: #selector(ViewController.panned(_:)))
        view.addGestureRecognizer(pan)
        
        // Tap anywhere on the screen to center the circle.
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapped(_:)))
        view.addGestureRecognizer(tap)
    }
    
    @objc
    func panned(_ gestureRecognizer: UIPanGestureRecognizer) {
        let location = gestureRecognizer.location(in: view)
        
        switch gestureRecognizer.state {
        case .began:
            startCircleLocation = circle.center
            startPanLocation = location
        case .changed:
            let offsetPoint = CGPoint(x: location.x - startPanLocation.x,
                                      y: location.y - startPanLocation.y)
            circle.center = CGPoint(x: startCircleLocation.x + offsetPoint.x,
                                    y: startCircleLocation.y + offsetPoint.y)
        default:
            break
        }
    }
    
    @objc
    func tapped(_ gestureRecognizer: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.25) {
            self.circle.center = self.view.center
        }
    }
}

