/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary view controller holding the toolbar and text view.
*/

import Cocoa

class ViewController: NSViewController, NSTextViewDelegate {
    
 	@IBOutlet var textView: NSTextView!
    
    // MARK: - NSTextViewDelegate
    
    func textView(_ textView: NSTextView,
                  shouldUpdateTouchBarItemIdentifiers identifiers: [NSTouchBarItem.Identifier]) -> [NSTouchBarItem.Identifier] {
        return [] // We want to show only our own NSTouchBarItem instances.
    }
    
}
