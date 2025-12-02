/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements a view controller introducing each flower product.
*/

import UIKit
import AVFoundation
import Vision

class ProductViewController: UIViewController {
    
    @IBOutlet var productView: UIView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var productPhoto: UIImageView!
    @IBOutlet weak var descriptionText: UITextView!
    
    var productID: String!
    var productCatalog: [String: [String: Any]]!
    
    @IBAction func dismissProductView(_ sender: Any) {
        dismiss(animated: true) {
            
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Read the product catalog from the plist file into the dictionary.
        if let path = Bundle.main.path(forResource: "ProductCatalog", ofType: "plist") {
            productCatalog = NSDictionary(contentsOfFile: path) as? [String: [String: Any]]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Give the view rounded corners.
        productView.layer.cornerRadius = 10
        productView.layer.masksToBounds = true
        
        if productID != nil {
            guard productCatalog[productID] != nil else {
                return
            }
            label.text = productCatalog[productID]?["label"] as? String
            descriptionText.text = productCatalog[productID]?["description"] as? String
            if let productImage = UIImage(named: productID + ".jpg") {
                productPhoto.image = productImage
            }
        }
    }
}
