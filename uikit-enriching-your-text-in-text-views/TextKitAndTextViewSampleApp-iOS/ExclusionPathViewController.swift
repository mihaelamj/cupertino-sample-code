/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller class that manages the text view for exclusion paths.
*/

import UIKit

class ExclusionPathViewController: UIViewController {
    @IBOutlet var textViewForExclusionPath: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        textViewForExclusionPath.keyboardDismissMode = .interactive
        textViewForExclusionPath.textStorage.loadExclusionPathSampleText()
        
        let bezierPath = ExclusionPath.uiBezierPath
        let origin = CGPoint(x: 50, y: 150)
        let scale = 0.6
        let tranform = CGAffineTransform.identity.translatedBy(x: origin.x, y: origin.y).scaledBy(x: scale, y: scale)
        bezierPath.apply(tranform)
        textViewForExclusionPath.textContainer.exclusionPaths = [bezierPath]
        
        let hammerImage = UIImage(imageLiteralResourceName: "Hammer")
        let imageSize = CGSize(width: hammerImage.size.width * scale, height: hammerImage.size.height * scale)
        
        // Exclusion paths use the text container's coordinate system, while the image view uses the text view's coordinate system,
        // so perform the conversion.
        let imageOrigin = CGPoint(x: origin.x + textViewForExclusionPath.textContainerInset.left,
                                  y: origin.y + textViewForExclusionPath.textContainerInset.top)
        let imageView = UIImageView(image: hammerImage)
        imageView.frame = CGRect(origin: imageOrigin, size: imageSize)
        textViewForExclusionPath.addSubview(imageView)
    }
}

