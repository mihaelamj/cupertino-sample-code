/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller class that manages the main UI.
*/

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var textViewForExclusionPath: NSTextView!
    @IBOutlet var textViewForAttachment: NSTextView!
    @IBOutlet var textViewForList: NSTextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the exclusion path.
        textViewForExclusionPath.textStorage?.loadExclusionPathSampleText()

        let bezierPath = ExclusionPath.nsBezierPath
        let origin = CGPoint(x: 75, y: 50)
        let scale = 1.0
        var transform = AffineTransform.identity
        transform.translate(x: origin.x, y: origin.y)
        transform.scale(scale)
        bezierPath.transform(using: transform)
        textViewForExclusionPath.textContainer?.exclusionPaths = [bezierPath]

        guard let hammerImage = NSImage(named: NSImage.Name("Hammer")) else {
            return
        }
        hammerImage.size = CGSize(width: hammerImage.size.width * scale, height: hammerImage.size.height * scale)
        let imageView = NSImageView(image: hammerImage)
        
        // By default, NSTextView has zero textContainerInset, so there's no need to do the coordinate system conversion.
        imageView.frame = CGRect(origin: origin, size: hammerImage.size)
        textViewForExclusionPath.addSubview(imageView)

        // Set up a view-based text attachment.
        textViewForAttachment.textStorage?.loadAttachmentSampleText(textLayoutManager: textViewForAttachment.textLayoutManager!)
        
        // Set up a list view and perform the initial population of the view.
        textViewForList.textStorage?.loadListSampleText()
    }
    
    @IBAction func setListMarkerStyle(_ sender: NSPopUpButton) {
        guard let textLayoutManager = textViewForList.textLayoutManager,
              let textStorage = textViewForList.textStorage else {
            return
        }
        let styleIndex = sender.indexOfSelectedItem
        textLayoutManager.textContentManager?.performEditingTransaction {
            textStorage.setListMarkerStyle(styleIndex: styleIndex)
        }
    }
}

