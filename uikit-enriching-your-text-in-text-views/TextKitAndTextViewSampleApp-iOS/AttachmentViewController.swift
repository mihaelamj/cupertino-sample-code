/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller class that manages the text view for text attachments.
*/

import UIKit

class AttachmentViewController: UIViewController {
    @IBOutlet var textViewForAttachment: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        textViewForAttachment.keyboardDismissMode = .interactive
        textViewForAttachment.textStorage.loadAttachmentSampleText(textLayoutManager: textViewForAttachment.textLayoutManager!)
    }
}
