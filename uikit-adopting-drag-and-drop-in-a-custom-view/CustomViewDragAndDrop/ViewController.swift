/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Demonstrates how to enable drag and drop for a UIImageView instance.
*/

import UIKit

class ViewController: UIViewController {
    // MARK: - Properties
    
    @IBOutlet weak var imageView: UIImageView! {
        didSet {
            imageView.layer.borderColor = UIColor.green.cgColor
            imageView.layer.borderWidth = 0.0
        }
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.borderColor = UIColor.red.cgColor
        
        // For an image view, you must explicitly enable user interaction to allow drag and drop.
        imageView.isUserInteractionEnabled = true
        
        // Enable dragging from the image view (see ViewController+Drag.swift).
        let dragInteraction = UIDragInteraction(delegate: self)
        imageView.addInteraction(dragInteraction)
        
        // Enable dropping onto the image view (see ViewController+Drop.swift).
        let dropInteraction = UIDropInteraction(delegate: self)
        view.addInteraction(dropInteraction)
    }
}
