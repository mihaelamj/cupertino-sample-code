/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Demonstrates configuring various types of controls as the right bar item of the navigation bar.
*/

import UIKit

class CustomRightViewController: UIViewController {
    
    struct SegmentedControl {
        static let textButton = 0
        static let imageButton = 1
        static let controlButton = 2
    }
    
    /// IBAction for the segmented control.
    @IBAction func changeRightBarItem(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case SegmentedControl.textButton:
            // Add a custom add button as the navigation bar's custom right view.
            let addButton = UIBarButtonItem(title: NSLocalizedString("AddTitle", comment: ""),
                                            style: .plain,
                                            target: self,
                                            action: #selector(action(_:)))
            navigationItem.rightBarButtonItem = addButton
            
        case SegmentedControl.imageButton:
            // Add the custom image button as the navigation bar's custom right view.
            let emailButton = UIBarButtonItem(image: UIImage(systemName: "envelope")!,
                                              style: .plain,
                                              target: self,
                                              action: #selector(action(_:)))
            navigationItem.rightBarButtonItem = emailButton
            
        case SegmentedControl.controlButton:
            // "Segmented" control to the right.
            let segmentedControl = UISegmentedControl(items: [
                UIImage(systemName: "arrow.up")!,
                UIImage(systemName: "arrow.down")!
            ])
            
            segmentedControl.addTarget(self, action: #selector(action), for: .valueChanged)
            segmentedControl.frame = CGRect(x: 0, y: 0, width: 90, height: 30)
            segmentedControl.isMomentary = true
            
            let segmentBarItem = UIBarButtonItem(customView: segmentedControl)
            navigationItem.rightBarButtonItem = segmentBarItem
            
        default:
            break
        }
    }
    
    // MARK: - Actions
    
    /// IBAction for the various bar button items shown in this example.
    @IBAction func action(_ sender: AnyObject) {
        Swift.debugPrint("CustomRightViewController IBAction invoked")
    }
    
}
