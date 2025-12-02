/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller class that manages the text view for text lists.
*/

import UIKit

class ListViewController: UIViewController {
    @IBOutlet var textViewForList: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        textViewForList.keyboardDismissMode = .interactive
        textViewForList.textStorage.loadListSampleText()
    }
    
    @IBAction func setListMarkerStyle(_ sender: UISegmentedControl) {
        guard let textLayoutManager = textViewForList.textLayoutManager else {
            return
        }
        let styleIndex = sender.selectedSegmentIndex
        let textStorage = textViewForList.textStorage
        textLayoutManager.textContentManager?.performEditingTransaction {
            textStorage.setListMarkerStyle(styleIndex: styleIndex)
        }
    }
}
