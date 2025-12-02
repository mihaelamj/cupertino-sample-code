/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller class for the main view, which displays a list of posts.
*/

import UIKit
import CoreData

class MainViewController: SpinnerViewController {
    @IBOutlet weak var composeItem: UIBarButtonItem!
    weak var detailViewController: DetailViewController?
    var sharingProvider: SharingProvider = AppDelegate.sharedAppDelegate.coreDataStack
    lazy var dataProvider: PostProvider = {
        let container = AppDelegate.sharedAppDelegate.coreDataStack.persistentContainer
        let provider = PostProvider(with: container,
                                    fetchedResultsControllerDelegate: self)
        return provider
    }()

    // MARK: - View controller life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.accessibilityIdentifier = "PostsTableView"
        navigationItem.leftBarButtonItem = editButtonItem
        
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        
        // Observe .didFindRelevantTransactions to update the user interface if needed.
        NotificationCenter.default.addObserver(
            self, selector: #selector(type(of: self).didFindRelevantTransactions(_:)),
            name: .didFindRelevantTransactions, object: nil)
        
        // Select the first row, if any, and update the detail view.
        didUpdatePost(nil)
    }

    /**
     Clear the tableView selection when splitViewController is collapsed.
     */
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    /**
     setEditing clears the current selection, which detailViewController relies on.
     
     Don’t preserve the selection. Select the first item, if any.
     */
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if !editing {
            tableView.reloadData()
            didUpdatePost(nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showDetail",
            let navController = segue.destination as? UINavigationController,
            let controller = navController.topViewController as? DetailViewController else {
                return
        }
        controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        controller.navigationItem.leftItemsSupplementBackButton = true
        
        if let indexPath = tableView.indexPathForSelectedRow {
            let post = dataProvider.fetchedResultsController.object(at: indexPath)
            controller.post = post
        }
        controller.delegate = self
        detailViewController = controller
    }
}

// MARK: - UITableViewDataSource and UITableViewDelegate

extension MainViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataProvider.fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as? PostCell else {
            fatalError("###\(#function): Failed to dequeue a PostCell. Check the cell reusable identifier in Main.storyboard.")
        }
        let post = dataProvider.fetchedResultsController.object(at: indexPath)
        cell.title.text = post.title
        cell.post = post
        cell.collectionView.reloadData()
        cell.collectionView.invalidateIntrinsicContentSize()
        
        if let attachments = post.attachments, attachments.allObjects.isEmpty {
            cell.hasAttachmentLabel.isHidden = true
        } else {
            cell.hasAttachmentLabel.isHidden = false
        }
        
        if sharingProvider.isShared(object: post) {
            let attachment = NSTextAttachment(image: UIImage(systemName: "person.circle")!)
            let attributedString = NSMutableAttributedString(attachment: attachment)
            attributedString.append(NSAttributedString(string: " " + (post.title ?? "")))
            cell.title.text = nil
            cell.title.attributedText = attributedString
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let post = dataProvider.fetchedResultsController.object(at: indexPath)
        dataProvider.delete(post: post) {
            self.didUpdatePost(nil)
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let post = dataProvider.fetchedResultsController.object(at: indexPath)
        return sharingProvider.canDelete(object: post)
    }
}

// MARK: - NSFetchedResultsControllerDelegate

extension MainViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
}

// MARK: - Handling didFindRelevantTransactions

extension MainViewController {
    /**
     Handle the didFindRelevantTransactions notification.
     */
    @objc
    func didFindRelevantTransactions(_ notification: Notification) {
        guard let relevantTransactions = notification.userInfo?["transactions"] as? [NSPersistentHistoryTransaction] else { preconditionFailure() }

        guard let detailViewController = detailViewController, let post = detailViewController.post else {
            update(with: relevantTransactions, select: nil)
            return
        }

        // Check if the current selected post is deleted or updated.
        // If not, and the user isn’t editing the selected post, merge the changes silently. Otherwise, alert the user, and go back to the main view.
        var isSelectedPostChanged = false
        var changeType: NSPersistentHistoryChangeType?
        
        loop0: for transaction in relevantTransactions {
            for change in transaction.changes! where change.changedObjectID == post.objectID {
                if change.changeType == .delete || change.changeType == .update {
                    isSelectedPostChanged = true
                    changeType = change.changeType
                    break loop0
                }
            }
        }
        
        // If the selection was not changed --- or it was changed, but the current peer isn’t editing it --- update the user interface silently.
        // If the user is viewing the full image and the post isn’t being edited, alert the user.
        if !isSelectedPostChanged ||
            (!detailViewController.isEditing && detailViewController.presentedViewController == nil) {
            if let changeType = changeType, changeType == .delete {
                update(with: relevantTransactions, select: nil)
            } else {
                update(with: relevantTransactions, select: post)
            }
            return
        }
        
        // The selected post was changed, and the user isn’t editing it.
        // Show an alert, and go back to the main view to reload everything after the user taps reload.
        let alert = UIAlertController(title: "Core Data CloudKit Alert",
                                      message: "This post has been deleted by a peer!",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Reload the main view", style: .default) {_ in
            if detailViewController.presentedViewController != nil {
                detailViewController.dismiss(animated: true) {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            } else {
                self.navigationController?.popToRootViewController(animated: true)
            }
            self.resetAndReload(select: post)
        })

        // Present the alert controller.
        var presentingViewController: UIViewController = detailViewController
        if detailViewController.presentedViewController != nil {
            presentingViewController = detailViewController.presentedViewController!
        }
        presentingViewController.present(alert, animated: true)
    }
    
    // Reset and reload the view controller if the transaction count is high. When there are only a few transactions, merge the changes one by one.
    // Ten is an arbitrary choice. Adjust this number based on performance.
    private func update(with transactions: [NSPersistentHistoryTransaction], select post: Post?) {
        if transactions.count > 10 {
            print("###\(#function): Relevant transactions:\(transactions.count), reset and reload.")
            resetAndReload(select: post)
            return
        }
        
        transactions.forEach { transaction in
            guard let userInfo = transaction.objectIDNotification().userInfo else { return }
            let viewContext = dataProvider.persistentContainer.viewContext
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: userInfo, into: [viewContext])
        }
        didUpdatePost(post)
    }
    
    /**
     Reset the viewContext, and reload the table view. Retain the selection, and call didUpdatePost to update the detail view controller.
     */
    func resetAndReload(select post: Post?) {
        dataProvider.persistentContainer.viewContext.reset()
        do {
            try dataProvider.fetchedResultsController.performFetch()
        } catch {
            fatalError("###\(#function): Failed to performFetch: \(error)")
        }
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        didUpdatePost(post)
    }
}

// MARK: - PostInteractionDelegate

extension MainViewController: PostInteractionDelegate {
    /**
     didUpdatePost is called as part of PostInteractionDelegate, or whenever a post update requires a UI update (including main-detail selections).
     
     Respond by updating the user interface as follows:
     - Add: Make the new item visible, and select it.
     - Add 1000: Preserve the current selection, if any; otherwise, select the first item.
     - Delete: Select the first item, if possible.
     - Delete all: Clear the detail view.
     - Update from detailViewController: Reload the row, make it visible, and select it.
     - Initial load: Select the first item, if needed.
     */
    func didUpdatePost(_ post: Post?, shouldReloadRow: Bool = false) {
        let rowCount = dataProvider.fetchedResultsController.fetchedObjects?.count ?? 0
        navigationItem.leftBarButtonItem?.isEnabled = (rowCount > 0) ? true : false

        // Get the indexPath for the post. Use the currently selected index path or the first row.
        // indexPath remains nil if the table view has no data.
        var indexPath: IndexPath?
        if let post = post {
            indexPath = dataProvider.fetchedResultsController.indexPath(forObject: post)
        } else {
            indexPath = tableView.indexPathForSelectedRow
            if indexPath == nil && tableView.numberOfRows(inSection: 0) > 0 {
                indexPath = IndexPath(row: 0, section: 0)
            }
        }
        
        // Update the mainViewController. Make sure the row is visible, and the content is up to date.
        if let indexPath = indexPath {
            if shouldReloadRow {
                tableView.reloadRows(at: [indexPath], with: .none)
            }
            if let isCollapsed = splitViewController?.isCollapsed, !isCollapsed {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
            tableView.scrollToRow(at: indexPath, at: .none, animated: true)
        }
        
        // Update the detailViewController if needed.
        // shouldReloadRow is true when the change was made in the detailViewController, so you don't need to update it.
        guard !shouldReloadRow else { return }
                
        // Reload the detailViewController if needed.
        guard let detailViewController = detailViewController else { return }
        
        if let indexPath = indexPath {
            detailViewController.post = dataProvider.fetchedResultsController.object(at: indexPath)
        } else {
            detailViewController.post = post
        }
        detailViewController.refreshUI()
    }
    
    /**
     UISplitViewController can load the detail view controller without notifying the main view controller, so manage the selection this way:
     
     - If the detailViewController isn't initialized, initialize it by setting up the delegate and post.
     - If the detailViewController is initialized and has a valid post, make sure the main view controller has the right selection.
     
     The main tableView selection is cleared when splitViewController is collapsed, so rely on the controller hierarchy to do the initialization.
     */
    func willShowDetailViewController(_ controller: DetailViewController) {
        if controller.delegate == nil {
            detailViewController = controller
            controller.delegate = self
        }
        
        if let post = controller.post {
            if tableView.indexPathForSelectedRow == nil {
                if let selectedRow = dataProvider.fetchedResultsController.indexPath(forObject: post) {
                    tableView.selectRow(at: selectedRow, animated: true, scrollPosition: .none)
                }
            }
        } else {
            if tableView.numberOfRows(inSection: 0) > 0 {
                didUpdatePost(nil)
            }
        }
    }
}
