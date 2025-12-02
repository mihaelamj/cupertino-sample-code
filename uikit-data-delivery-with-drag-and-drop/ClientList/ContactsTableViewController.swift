/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Table View Controller that implements drag and drop delegates.
*/

import UIKit

// MARK: - UITableViewDataSource

final class ClientsDataSource: NSObject, UITableViewDataSource {

    static let tableCellIdentifier = "contactNameCell"

    var clients: [ContactCard] = [
        ContactCard(name: "Jane Doe", phone: "(444) 444-4444", picture: #imageLiteral(resourceName: "female")),
        ContactCard(name: "John Doe", phone: "(555) 555-5555", picture: #imageLiteral(resourceName: "male")),
        ContactCard(name: "Mr Z", phone: "(111) 111-1111", picture: #imageLiteral(resourceName: "male")),
        ContactCard(name: "Mr X", phone: "(222) 222-2222", picture: #imageLiteral(resourceName: "gender-neutral")),
        ContactCard(name: "Dr S", phone: "(888) 888-8888", picture: #imageLiteral(resourceName: "gender-neutral")),
        ContactCard(name: "Sir M", phone: "(333) 333-3333", picture: #imageLiteral(resourceName: "male")),
        ContactCard(name: "Lady J", phone: "(777) 777-7777", picture: #imageLiteral(resourceName: "gender-neutral")),
        ContactCard(name: "Miss L", phone: "(999) 999-9999", picture: #imageLiteral(resourceName: "female")),
        ContactCard(name: "Mrs B", phone: "(666) 666-6666", picture: #imageLiteral(resourceName: "female"))]

    func client(index: Int) -> ContactCard {
        return clients[index]
    }

    func moveClient(at sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath, in tableView: UITableView) {
        tableView.performBatchUpdates({ () -> Void in
            let contact = clients[sourceIndexPath.item]
            clients.remove(at: sourceIndexPath.item)
            clients.insert(contact, at: destinationIndexPath.item)
            tableView.deleteRows(at: [sourceIndexPath], with: .automatic)
            tableView.insertRows(at: [destinationIndexPath], with: .automatic)
        }, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clients.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let client = clients[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ClientsDataSource.tableCellIdentifier, for: indexPath)
        cell.textLabel?.text = client.name
        return cell
    }
}

// MARK: - ContactsTableViewController

class ContactsTableViewController: UITableViewController {

    // Our data source is an array of client vCards.
    let dataSource = ClientsDataSource()

    // MARK: - ViewController Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dropDelegate = self
        tableView.dragDelegate = self

        tableView.dataSource = dataSource
    }

    // MARK: - Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailsSegue" {
            if let detailsViewController = segue.destination as? ContactDetailsViewController {
                let contactCard = dataSource.clients[tableView.indexPathForSelectedRow!.row]
                detailsViewController.contactCard = contactCard
            }
        }
    }

    // MARK: - Alerts

    func displayError(_ error: Error?) {
        let alert =
            UIAlertController(title: "Unable to load object",
                              message: error?.localizedDescription,
                              preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

}

// MARK: - UITableViewDropDelegate

extension ContactsTableViewController: UITableViewDropDelegate {
    /**
     This delegate method is the only opportunity for accessing and loading the data representations
     offered in the drag item. The drop coordinator supports accessing the dropped items, updating
     the table view, and specifying optional animations. Local drags with one item go through the
     existing `tableView(_:moveRowAt:to:)` method on the data source.
     
     In addition to contact cards, we accept generic strings dropped in which will create a new
     contact with that string being the new name.
     */
    /// - Tag: ContactsTableViewControllerPerformDrop
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {

        // If the drop location is unspecified, this is nil.
        let destinationIndexPath = coordinator.destinationIndexPath

        for dropItem in coordinator.items {
            if let sourceIndexPath = dropItem.sourceIndexPath {
                /*
                 Local drag:
                 Contact being dropped within the table, just reorder the table view.
                 */
                dataSource.moveClient(at: sourceIndexPath, to: destinationIndexPath!, in: tableView)
                coordinator.drop(dropItem.dragItem, toRowAt: destinationIndexPath!)
            } else {
                /*
                 Promised drag:
                 Promise based object from another app, let's insert a placeholder.
                 */
                if coordinator.proposal.intent == .insertAtDestinationIndexPath {
                    /*
                     The drop will be placed in row(s) inserted at the destination index path.
                     Opens a gap at the specified location simulating the final dropped layout.
                     */
                    _ = dropItem.dragItem.itemProvider.loadObject(
                        ofClass: ContactCard.self,
                        completionHandler: { (data, error) in
                            if error == nil {
                                DispatchQueue.main.async {
                                    let placeHolder = UITableViewDropPlaceholder(
                                        insertionIndexPath: destinationIndexPath!,
                                        reuseIdentifier: ClientsDataSource.tableCellIdentifier,
                                        rowHeight: UITableView.automaticDimension)

                                    let placeHolderContext = coordinator.drop(dropItem.dragItem, to: placeHolder)

                                    placeHolderContext.commitInsertion(dataSourceUpdates: { (insertionIndexPath) in
                                        // Update our data source with the newly dropped contact.
                                        if let newContact = data as? ContactCard {
                                            self.dataSource.clients.insert(newContact, at: insertionIndexPath.item)
                                        }
                                    })
                                }
                            } else {
                                print("""
                                    There was an error in loading the drop item: ### \(#function),
                                    \(String(describing: error?.localizedDescription))
                                    """)
                            }
                        })
                } else if coordinator.proposal.intent == .unspecified {
                    /*
                     Unspecified drop:
                     Table view accepts the drop, but the location is not yet known and will be determined later.
                     Will not open a gap. Here we simple append the cards to the end of our contacts.
                     */
                    _ = dropItem.dragItem.itemProvider.loadObject(
                        ofClass: ContactCard.self,
                        completionHandler: { (data, error) in
                            if error == nil {
                                if let newContact = data as? ContactCard {
                                    self.dataSource.clients.append(newContact)
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                    }
                                }
                            } else {
                                print("""
                                    There was an error in loading the drop item: ### \(#function),
                                    \(String(describing: error?.localizedDescription))
                                    """)
                            }
                        })
                } else if coordinator.proposal.intent == .insertIntoDestinationIndexPath {
                    /*
                     The drop is being placed inside the item at the destination index path
                     (e.g. the item is a container of other items). Will not open a gap.
                     Collection view will highlight the item at the destination index path.
                     */
                }
            }
        }
    }

    /**
     Called frequently while the drop session being tracked inside the table view's coordinate space.
     
     A drop proposal from a table view includes two items:
     a drop operation (typically .move or .copy),
     an intent, which declares the action the table view will take upon receiving the items.
     
     When the drop is at the end of a section, the destination index path passed will be for a row
     that does not yet exist (equal to the number of rows in that section), where an inserted row would
     append to the end of the section. The destination index path may be nil in some circumstances
     (e.g. when dragging over empty space where there are no cells). Note that in some cases your
     proposal may not be allowed and the system will enforce a different proposal. You may perform your
     own hit testing by calling session.location(in:).
     
     If you don't want cells to be inserted as you drag, don't implement this method.
     */
    func tableView(_ tableView: UITableView,
                   dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {

        var dropProposal: UITableViewDropProposal

        // The .move operation is available only for dragging within a single app.
        if tableView.hasActiveDrag {
            // The drag is occurring within the table.
            if session.items.count > 1 {
                // We don't allow dropping multiple items.
                return UITableViewDropProposal(operation: .cancel)
            } else {
                // The .move operation is available only for dragging within a single app.
                return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            }
        } else {
            dropProposal = UITableViewDropProposal(operation: .copy, intent: .insertAtDestinationIndexPath)
        }

        return dropProposal
    }

    /**
     If NO is returned no further delegate methods will be called for this drop session.
     If not implemented, a default value of YES is assumed.
     */
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        //print("### \(#function)")
        return true
    }

    /// Called when the drop session is no longer being tracked inside the table view's coordinate space.
    func tableView(_ tableView: UITableView, dropSessionDidExit session: UIDropSession) {
        //print("### \(#function)")
    }

    /// Called when the drop session completed, regardless of outcome. Useful for performing any cleanup.
    func tableView(_ tableView: UITableView, dropSessionDidEnd session: UIDropSession) {
        //print("### \(#function)")
    }

    /// Called when the drop session begins tracking in the table view's coordinate space.
    func tableView(_ tableView: UITableView, dropSessionDidEnter session: UIDropSession) {
        //print("### \(#function)")
    }
}

// MARK: - UITableViewDragDelegate

extension ContactsTableViewController: UITableViewDragDelegate {
    /**
     The `tableView(_:itemsForBeginning:at:)` method is the essential method
     to implement for allowing dragging from a table.
     */
    func tableView(_ tableView: UITableView,
                   itemsForBeginning session: UIDragSession,
                   at indexPath: IndexPath) -> [UIDragItem] {
        let contactCard = dataSource.clients[indexPath.row]
        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: contactCard))
        return [dragItem]
    }

    /**
     Multiple dragging:
     Called to request items to add to an existing drag session in response to the add item gesture.
     You can use the provided point (in the table view's coordinate space) to do additional hit testing
     if desired. If not implemented, or if an empty array is returned, no items will be added to the
     drag and the gesture will be handled normally.
     */
    func tableView(_ tableView: UITableView,
                   itemsForAddingTo session: UIDragSession,
                   at indexPath: IndexPath,
                   point: CGPoint) -> [UIDragItem] {
        // use this to NOT allow additional items to the drag:
        // return []

        let contactCard = dataSource.clients[indexPath.row]
        let dragItem = UIDragItem(itemProvider: NSItemProvider(object: contactCard))
        dragItem.localObject = true // makes it faster to drag and drop content within the same app
        return [dragItem]
    }

    /**
     Allows customization of the preview used for the row when it is lifted or if the drag cancels.
     If not implemented or if nil is returned, the entire cell will be used for the preview.
     */
    func tableView(_ tableView: UITableView,
                   dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        // Make the dragged cell slightly larger during the drag.
        let cell = tableView.cellForRow(at: indexPath)
        let parameters = UIDragPreviewParameters()
        parameters.visiblePath = UIBezierPath(rect: (cell?.bounds.insetBy(dx: -10, dy: -10))!)
        parameters.backgroundColor = UIColor.clear
        return parameters
    }

    /**
     Called after the lift animation has completed to signal the start of a drag session.
     This call will always be balanced with a corresponding call to -tableView:dragSessionDidEnd:
     */
    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        //print("### \(#function)")
    }

    /// Called to signal the end of the drag session.
    func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {
        //print("### \(#function)")
    }

}
