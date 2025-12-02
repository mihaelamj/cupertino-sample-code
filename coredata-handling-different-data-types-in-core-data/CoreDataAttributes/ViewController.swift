/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A UIViewController subclass which displays a collection of books in a table view.
*/

import UIKit
import CoreData

class ViewController: UITableViewController {

    private lazy var persistentContainer: NSPersistentContainer = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        return appDelegate!.persistentContainer
    }()

    private lazy var fetchedResultsController: NSFetchedResultsController<Book> = {
        let fetchRequest: NSFetchRequest<Book> = Book.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: Book.Name.publishDate, ascending: true)]

        let controller = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                    managedObjectContext: persistentContainer.viewContext,
                                                    sectionNameKeyPath: Book.Name.publishMonthID, cacheName: nil)
        controller.delegate = self
    
        do {
            try controller.performFetch()
        } catch {
            fatalError("###\(#function): Failed to performFetch: \(error)")
        }
        return controller
    }()

    // Create date formatters and cache them for later use.
    // Use the default (current) calendar, time zone, and locale
    // as these formatters will be used to generate user-visible date strings.
    //
    private lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        return dateFormatter
    }()

    private var dateFormatterForSectionHeader: DateFormatter {
        dateFormatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return dateFormatter
    }
    
    private var dateFormatterForRowTitle: DateFormatter {
        dateFormatter.setLocalizedDateFormatFromTemplate("EEEE, MMM d, yyyy")
        return dateFormatter
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        
        #if targetEnvironment(macCatalyst)
            title = ""
        #endif
    }
}

// MARK: - UITableViewDataSource and UITableViewDelegate
//
extension ViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "BookCell", for: indexPath) as? BookCell else {
            fatalError("###\(#function): Failed to dequeue a BookCell. Check the cell reusable identifier in Main.storyboard.")
        }
        let book = fetchedResultsController.object(at: indexPath)
        cell.title.text = book.title
        cell.title.textColor = book.tintColor
        
        cell.price.text = book.price?.description(withLocale: Locale.current)
        
        cell.price.textColor = book.tintColor

        if let publishDate = book.publishDate {
            cell.publishDate.text = "Published on: " + dateFormatterForRowTitle.string(from: publishDate)
        }
        
        // Convert RTF data to NSAttributedString.
        //
        if let data = book.abstract,
            let attributedString = try? NSAttributedString(
                data: data, options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil) {
            cell.abstract.attributedText = attributedString
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sections = fetchedResultsController.sections, !sections.isEmpty,
            let date = Book.date(from: sections[section].name) else {
            return nil
        }
        return dateFormatterForSectionHeader.string(from: date)
    }
}

// MARK: - NSFetchedResultsControllerDelegate
//
extension ViewController: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.reloadData()
    }
}

// MARK: - UISearchResultsUpdating
//
extension ViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        let predicate: NSPredicate
        if let userInput = searchController.searchBar.text, !userInput.isEmpty {

            // Searching title with "diacritic insensitive" option gets the same result:
            //     predicate = NSPredicate(format: "title CONTAINS[cd] %@", userInput)
            // However, searching canonicalTitle avoids doing diacritic insensitive comparison every time,
            // and hence has better performance.
            //
            predicate = NSPredicate(format: "canonicalTitle CONTAINS[c] %@", userInput)
        } else {
            predicate = NSPredicate(value: true)
        }

        fetchedResultsController.fetchRequest.predicate = predicate
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("###\(#function): Failed to performFetch: \(error)")
        }
        
        tableView.reloadData()
    }
}
