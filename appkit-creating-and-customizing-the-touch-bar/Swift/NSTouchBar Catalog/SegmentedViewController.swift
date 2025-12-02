/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing segmented controls in an NSTouchBar instance.
*/

import Cocoa

class SegmentedViewController: NSViewController {

    @IBAction func segmentAction(_ sender: Any?) {
        if let segmented = sender as? NSSegmentedControl {
            print("\(#function) is called. Segment \(segmented.selectedSegment)")
        }
    }
    
}
