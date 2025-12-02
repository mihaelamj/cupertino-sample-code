/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller that displays options for presenting sheets.
*/

import UIKit

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var largestUndimmedDetentIdentifierControl: UISegmentedControl!
    @IBOutlet weak var prefersScrollingExpandsWhenScrolledToEdgeSwitch: UISwitch!
    @IBOutlet weak var prefersEdgeAttachedInCompactHeightSwitch: UISwitch!
    @IBOutlet weak var widthFollowsPreferredContentSizeWhenEdgeAttachedSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let selectedSegmentIndex: Int
        switch PresentationHelper.sharedInstance.largestUndimmedDetentIdentifier {
        case .small:
            selectedSegmentIndex = 0
        case .medium:
            selectedSegmentIndex = 1
        default:
            selectedSegmentIndex = 2
        }
        largestUndimmedDetentIdentifierControl.selectedSegmentIndex = selectedSegmentIndex
        
        prefersScrollingExpandsWhenScrolledToEdgeSwitch.isOn =
        PresentationHelper.sharedInstance.prefersScrollingExpandsWhenScrolledToEdge
        
        prefersEdgeAttachedInCompactHeightSwitch.isOn =
        PresentationHelper.sharedInstance.prefersEdgeAttachedInCompactHeight
        
        widthFollowsPreferredContentSizeWhenEdgeAttachedSwitch.isOn =
        PresentationHelper.sharedInstance.widthFollowsPreferredContentSizeWhenEdgeAttached
    }
    
    @IBAction func largestUndimmedDetentChanged(_ sender: UISegmentedControl) {
        let largestUndimmedDetentIdentifier: UISheetPresentationController.Detent.Identifier
        switch sender.selectedSegmentIndex {
        case 0:
            largestUndimmedDetentIdentifier = .small
        case 1:
            largestUndimmedDetentIdentifier = .medium
        default:
            largestUndimmedDetentIdentifier = .large
        }
        
        PresentationHelper.sharedInstance.largestUndimmedDetentIdentifier = largestUndimmedDetentIdentifier
        updateSheet()
    }
    
    @IBAction func prefersScrollingExpandsWhenScrolledToEdgeSwitchChanged(_ sender: UISwitch) {
        PresentationHelper.sharedInstance.prefersScrollingExpandsWhenScrolledToEdge = sender.isOn
        updateSheet()
    }
    
    @IBAction func prefersEdgeAttachedInCompactHeightSwitchChanged(_ sender: UISwitch) {
        PresentationHelper.sharedInstance.prefersEdgeAttachedInCompactHeight = sender.isOn
        updateSheet()
    }
    
    @IBAction func widthFollowsPreferredContentSizeWhenEdgeAttachedChanged(_ sender: UISwitch) {
        PresentationHelper.sharedInstance.widthFollowsPreferredContentSizeWhenEdgeAttached = sender.isOn
        updateSheet()
    }
    
    func updateSheet() {
        guard let sheet = popoverPresentationController?.adaptiveSheetPresentationController else {
            return
        }
        sheet.largestUndimmedDetentIdentifier =
        PresentationHelper.sharedInstance.largestUndimmedDetentIdentifier
        sheet.prefersScrollingExpandsWhenScrolledToEdge =
        PresentationHelper.sharedInstance.prefersScrollingExpandsWhenScrolledToEdge
        sheet.prefersEdgeAttachedInCompactHeight =
        PresentationHelper.sharedInstance.prefersEdgeAttachedInCompactHeight
        sheet.widthFollowsPreferredContentSizeWhenEdgeAttached =
        PresentationHelper.sharedInstance.widthFollowsPreferredContentSizeWhenEdgeAttached
    }
}
