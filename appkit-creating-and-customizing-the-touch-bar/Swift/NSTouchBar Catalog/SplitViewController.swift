/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Main split-view controller for this sample (primary = table of tests, detail = each view controller test).
*/

import Cocoa

class SplitViewController: NSSplitViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        splitView.autosaveName = "SplitViewAutosSave"
        minimumThicknessForInlineSidebars = 10.0
    }
    
}

