/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Table View support for the primary view controller.
*/

import SwiftUI

// MARK: - UITableViewDataSource

extension PrimaryViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel!.text = tableItems[indexPath.row].description
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false to now allow specified item to be editable.
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableItems.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            detailViewController.detailItem = nil
            
            if tableView.numberOfRows(inSection: 0) == 0 {
                // No more cells to delete, so exit edit mode.
                setEditing(false, animated: true)
            }
        }
    }
    
}

// MARK: - UITableViewDelegate

extension PrimaryViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectDetailItem(indexPath: indexPath)
    }

}
