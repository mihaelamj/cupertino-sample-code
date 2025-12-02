/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A table view controller for displaying the entire contents of the database as a feed of colors.
*/

import UIKit
import CoreData

class FeedTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    var server: Server!
    var fetchRequest: NSFetchRequest<FeedEntry>!
    
    private var fetchedResultsController: NSFetchedResultsController<FeedEntry>!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        
        if fetchRequest == nil {
            fetchRequest = FeedEntry.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(FeedEntry.timestamp), ascending: false)]
        }
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: PersistentContainer.shared.viewContext,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: String(describing: self))
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Error fetching results: \(error)")
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if fetchedResultsController.sections?.count ?? 0 > 0 {
            let sectionInfo = fetchedResultsController.sections![section]
            return sectionInfo.numberOfObjects
        } else {
            return 0
        }
    }

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any, at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        case .update:
            if let cell = tableView.cellForRow(at: indexPath!) as? FeedEntryTableViewCell {
                configure(cell: cell, at: indexPath!)
            }
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else { return }
            tableView.moveRow(at: indexPath, to: newIndexPath)
        default:
            return
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "entryCell",
                                                       for: indexPath) as? FeedEntryTableViewCell else {
            fatalError("Could not dequeue cell")
        }
        configure(cell: cell, at: indexPath)
        return cell
    }

    func configure(cell: FeedEntryTableViewCell, at indexPath: IndexPath) {
        let feedEntry = fetchedResultsController.object(at: indexPath)
        cell.feedEntry = feedEntry
    }
        
    @IBAction private func fetchLatestEntries(_ sender: UIRefreshControl) {
        sender.beginRefreshing()
        
        let queue = OperationQueue()
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 1
        
        let context = PersistentContainer.shared.newBackgroundContext()
        let operations = Operations.getOperationsToFetchLatestEntries(using: context, server: server)
        operations.last?.completionBlock = {
            DispatchQueue.main.async {
                sender.endRefreshing()
            }
        }
        
        queue.addOperations(operations, waitUntilFinished: false)
    }
    
    @IBAction private func showActions(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.barButtonItem = sender
        
        alertController.addAction(UIAlertAction(title: "Reset Feed Data", style: .destructive, handler: { _ in
            PersistentContainer.shared.loadInitialData(onlyIfNeeded: false)
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
}
