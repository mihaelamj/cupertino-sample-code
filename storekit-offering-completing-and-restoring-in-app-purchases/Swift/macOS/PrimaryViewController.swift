/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The base table view controller for sharing a table view between subclasses.
*/

import Cocoa

class PrimaryViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    // MARK: - Properties
    
    /// The data model that all PrimaryViewController subclasses use.
    var data = [Any]()
    
    /// The table view that all PrimaryViewController subclasses use.
    @IBOutlet weak var tableView: NSTableView!
    
    // MARK: - NSTable​View​Data​Source
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return data.count
    }
}

