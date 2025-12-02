/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The base table view controller for sharing a table view between subclasses.
*/

import UIKit

class BaseViewController: UITableViewController {
    // MARK: - Properties
    
    /// The data model that all BaseViewController subclasses use.
    var data = [Section]()
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Returns the number of sections.
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Returns the number of rows in the section.
        return data[section].elements.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Returns the header title for this section.
        return data[section].type.description
    }
}

// MARK: - BaseViewController Extension

/// Extends BaseViewController to refresh the UI with new data.
extension BaseViewController {
    func reload(with data: [Section]) {
        self.data = data
        tableView.reloadData()
    }
}
