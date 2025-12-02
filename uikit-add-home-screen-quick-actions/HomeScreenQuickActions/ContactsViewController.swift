/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A table view controller showing the sample contact data and allowing the detail view controller to be displayed.
*/

import UIKit

class ContactsViewController: UITableViewController {

    // MARK: - View life cycle

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // If there is a selected row, refresh it as the data may have been updated.
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.reloadRows(at: [ selectedIndexPath ], with: .automatic)
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ContactsData.shared.contacts.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)

        let contact = ContactsData.shared.contacts[indexPath.row]
        cell.textLabel?.text = contact.name

        return cell
    }

    // MARK: - Segue preparation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let selectedTableViewCell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: selectedTableViewCell)
            else { preconditionFailure("Expected sender to be a valid table view cell") }

        guard let contactDetailViewController = segue.destination as? ContactDetailViewController
            else { preconditionFailure("Expected a ContactDetailViewController") }

        // Pass over a reference to the selected contact.
        contactDetailViewController.contact = ContactsData.shared.contacts[indexPath.row]
    }

}
