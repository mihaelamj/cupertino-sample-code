/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension of MainViewController that implements UITableViewDelegate.
*/

import UIKit

extension MainViewController {
    // Override to support deleting a table view item by swiping left.
    // There is no need to apply a new snapshot because deleting a document (removeDocument) triggers NSMetadataQueryDidUpdate,
    // and the update event handler updates the table view.
    //
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "") { (_, _, completionHandler) in
            if let metadataItem = self.diffableMetadataSource.itemIdentifier(for: indexPath) {
                self.removeDocument(at: metadataItem.url)
            }
            completionHandler(true)
        }
        deleteAction.image = UIImage(systemName: "trash.fill")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    // Override willSelectRowAt to prevent the tableView from switching selection when
    // the detail view controller is editing.
    //
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // If the target indexPath is currently selected, quietly return.
        //
        if let targetIndexPath = tableView.indexPathForSelectedRow, targetIndexPath == indexPath {
            return nil
        }
        
        // If the detail view controller isn't editing, allows the selection switching.
        // Otherwise, alert the user and return nil to prevent the switching.
        //
        guard let detailViewController = detailViewController(), detailViewController.isEditing else {
            return indexPath
        }
        
        let newAlert = UIAlertController(title: "Warning",
                                         message: "Please finish your current edit session before loading a new document.",
                                         preferredStyle: .alert)
        newAlert.addAction(UIAlertAction(title: "OK", style: .default))
        present(newAlert, animated: true)
        return nil
    }
    
    // Find and return the detail view controller via splitViewController if there is one.
    //
    private func detailViewController() -> DetailViewController? {
        guard let splitViewController = splitViewController, !splitViewController.isCollapsed else {
            return nil
        }
        let count = splitViewController.viewControllers.count
        let navigationController = splitViewController.viewControllers[count - 1] as? UINavigationController
        let topViewController = navigationController?.topViewController as? UINavigationController
        let detailNavigationController = topViewController ?? navigationController

        return detailNavigationController?.topViewController as? DetailViewController
    }
}

