/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A UIViewController subclass displaying a collection of books in a table view.
*/

import UIKit
import CoreData

class MainViewController: UITableViewController {
        
    private lazy var persistentContainer: NSPersistentContainer = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        return appDelegate!.persistentContainer
    }()

    private lazy var fetchedResultsController: NSFetchedResultsController<Book> = {
        let fetchRequest: NSFetchRequest<Book> = Book.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: persistentContainer.viewContext,
                                                    sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = self
        do {
            try controller.performFetch()
        } catch {
            fatalError("###\(#function): Failed to performFetch: \(error)")
        }
        return controller
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        #if targetEnvironment(macCatalyst)
        navigationController?.navigationBar.isHidden = true
        #endif
    }

}

// MARK: - UITableViewDataSource and UITableViewDelegate
//
extension MainViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let book = fetchedResultsController.fetchedObjects?[section]
        return book?.feedbackList?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let views = Bundle.main.loadNibNamed("SectionTitleView", owner: self, options: nil),
            let sectionTitleView = views[0] as? SectionTitleView else { return nil }
        
        sectionTitleView.section = section
        let book = fetchedResultsController.fetchedObjects?[section]
        sectionTitleView.title.text = book?.title
        return sectionTitleView
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedbackCell", for: indexPath)

        if let book = fetchedResultsController.fetchedObjects?[indexPath.section] {
            guard let feedback = book.feedbackList?[indexPath.row] else { return cell }
            let rating = Int(feedback.rating)
            let comment = feedback.comment ?? ""
            cell.textLabel?.text = ["👍", "👊", "👎"][rating] + " " + comment
            cell.textLabel?.textColor = [UIColor.systemGreen, UIColor.systemGray, UIColor.systemRed ][rating]
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        if let book = fetchedResultsController.fetchedObjects?[indexPath.section], let context = book.managedObjectContext,
            let feedback = book.feedbackList?[indexPath.row] {
            context.delete(feedback)
            do {
                try context.save()
            } catch {
                print("Failed to save feedback: \(error)")
            }
            context.refresh(book, mergeChanges: true)
        }
    }
}

// MARK: - NSFetchedResultsControllerDelegate
//
extension MainViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}

// MARK: - Actions
//
extension MainViewController {
    
    @IBAction func addOneFeedback(_ sender: Any) {
        guard let sectionTitleView = (sender as? UIView)?.superview as? SectionTitleView,
            let book = fetchedResultsController.fetchedObjects?[sectionTitleView.section] else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let navController = storyboard.instantiateViewController(withIdentifier: "FeedbackViewControllerNav") as? UINavigationController,
            let feedbackViewController = navController.viewControllers[0] as? FeedbackViewController else { return }

        feedbackViewController.book = book
        present(navController, animated: true)
    }
}
