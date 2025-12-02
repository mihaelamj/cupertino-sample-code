/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A table view controller showing that supports a two-finger pan gesture for
 selecting multiple rows.
*/

import UIKit

private let reuseIdentifier = "reuseIdentifier"

class TableViewController: UITableViewController {

    let items = FillerModel.generateFillerItems(count: 100)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsMultipleSelection = false
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.allowsFocus = true
        tableView.allowsFocusDuringEditing = true
        
        navigationItem.rightBarButtonItem = editButtonItem
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        cell.textLabel?.text = items[indexPath.row].title
        cell.detailTextLabel?.text = items[indexPath.row].descriptionText
        cell.detailTextLabel?.numberOfLines = 0

        return cell
    }

    // MARK: - Multiple selection methods.

    /// - Tag: table-view-should-begin-multi-select
    override func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return true
    }

    /// - Tag: table-view-did-begin-multi-select
    override func tableView(_ tableView: UITableView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        // Replace the Edit button with Done, and put the
        // table view into editing mode.
        self.setEditing(true, animated: true)
    }
    
    /// - Tag: table-view-did-end-multi-select
    override func tableViewDidEndMultipleSelectionInteraction(_ tableView: UITableView) {
        print("\(#function)")
    }

}
