/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller class that manages metadata items in iCloud container.
*/

import UIKit

class MainViewController: UITableViewController {
    struct SegueID {
        static let showDetail = "ShowDetail"
    }
        
    private(set) var metadataProvider: MetadataProvider?

    // The diffable metadata data source for the main table view.
    //
    lazy var diffableMetadataSource: DiffableMetadataSource! = {
        return DiffableMetadataSource(tableView: tableView) { (tableView, indexPath, metadata) -> UITableViewCell? in
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            let url = metadata.url
            cell.textLabel!.text = url.lastPathComponent
            cell.textLabel!.textColor = self.isDocumentScopeURL(url) ? .blue : .black
            cell.detailTextLabel?.text = ""
            cell.accessoryType = self.splitViewController!.isCollapsed ? .disclosureIndicator : .none
            return cell
        }
    }()
}

// MARK: - UIViewController overridable
//
extension MainViewController {
    // Set up the navigation and toolbar items, create the metadata provider,
    // and set up the notification observation.
    //
    /// - Tag: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = editButtonItem
        diffableMetadataSource.defaultRowAnimation = .fade

        // Initialize metadataProvider using the iCloud container identifier.
        // An iCloud container identifier is case- sensitive and must begin with "iCloud.".
        // You can pass nil if your identifier is in the form "iCloud.<bundle identifier>".
        //
        metadataProvider = MetadataProvider(containerIdentifier: nil)
        
        // Observe .metadataDidChange to update the UI, if necessary.
        //
        NotificationCenter.default.addObserver(
            self, selector: #selector(Self.metadataDidChange(_:)),
            name: .sicdMetadataDidChange, object: nil)
    }

    // Clear the selection when the splitViewController is in a collapsed state.
    //
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    // When the splitViewController is in a collapsed state,
    // UIKit can remove the table view from the view hierarchy, so it may not be up to date.
    // Grab the metadata items directly and update the table view with them.
    //
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if splitViewController!.isCollapsed, let provider = metadataProvider {
            updateTableView(with: provider.metadataItemList())
        }
    }
    
    // Prepare for presenting a detail view controller (SegueID.showDetail).
    // When presenting a document from Open-in-Place, the sender is a file URL.
    // When tableView.indexPathForSelectedRow is nil, detailViewController presents an empty UI.
    //
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == SegueID.showDetail else { return }
        
        guard let navController = segue.destination as? UINavigationController,
              let detailViewController = navController.topViewController as? DetailViewController else {
            fatalError("Failed to load the detail view controller.")
        }
        
        // If the sender is a URL, open it.
        // This happens when the URL points to an external document from open-in-place.
        //
        if let url = sender as? URL {
            detailViewController.document = Document(fileURL: url)
            return
        }
        
        // Create a document with the fileURL for the selected row, and pass it through.
        // When tableView.indexPathForSelectedRow is nil, detailViewController presents an empty UI.
        //
        if let indexPath = tableView.indexPathForSelectedRow,
           let metadata = diffableMetadataSource.itemIdentifier(for: indexPath) {
            detailViewController.document = Document(fileURL: metadata.url)
        }
    }
}

// MARK: - Actions and notifications
//
extension MainViewController {
    // The action handler of the add button.
    // Present an alert controller for users to create a new document.
    //
    @IBAction func add(_ sender: Any) {
        let alert = UIAlertController(title: "New Document", message: "Creating a new document", preferredStyle: .alert)
        alert.addTextField() { textField -> Void in textField.placeholder = "Document name" }

        let completionHandler: (Bool) -> Void = { success in
            guard !success else { return }
            print("Failed to save a document!")
        }
        
        // If the input field is empty, the document name defaults to "Untitled".
        // This sample doesn't handle potential name conflicts because that isn't the focus.
        //
        alert.addAction(UIAlertAction(title: "Save to Documents", style: .default) { _ in
            guard let fileName = alert.textFields![0].text else { return }
            self.createDocument(with: fileName, scope: .documents,
                                content: "", completionHandler: completionHandler)
        })
        
        alert.addAction(UIAlertAction(title: "Save to Data", style: .default) { _ in
            guard let fileName = alert.textFields![0].text else { return }
            self.createDocument(with: fileName, scope: .data,
                                content: "", completionHandler: completionHandler)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .default))

        present(alert, animated: true)
    }
        
    // The handler of the .metadataDidChange notification.
    // Grab the metadata items from notification.userInfo and update the table view.
    //
    @objc
    func metadataDidChange(_ notification: Notification) {
        guard notification.object is MetadataProvider,
              let userInfo = notification.userInfo as? MetadataProvider.MetadataDidChangeUserInfo,
              let metadataItemList = userInfo[.queryResults],
              tableView.window != nil else {
            return
        }
        // Retrieve the selected item before updating the table view to restore it later.
        //
        var itemToBeSelected: MetadataItem?
        if let indexPath = tableView.indexPathForSelectedRow,
           let item = diffableMetadataSource.itemIdentifier(for: indexPath),
           let index = metadataItemList.firstIndex(where: { $0.nsMetadataItem == item.nsMetadataItem }) {
            itemToBeSelected = metadataItemList[index]
        }
        
        updateTableView(with: metadataItemList)
        
        // If the table view was in a selected state before updating, restore the selected item.
        // Otherwise, keep the table view in an unselected state.
        // This sample doesn't manage the documents outside of the iCloud container,
        // so the table view isn't in a selected state when users open an external document in place.
        //
        guard let splitViewController = splitViewController, !splitViewController.isCollapsed,
              diffableMetadataSource.tableView(tableView, numberOfRowsInSection: 0) > 0 else {
            return
        }
        if let itemToBeSelected = itemToBeSelected,
           let indexPath = diffableMetadataSource.indexPath(for: itemToBeSelected) {
            tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
        }
    }
    
    // Update the table view by creating and applying a new snapshot.
    //
    private func updateTableView(with metadataItemList: [MetadataItem]) {
        var snapshot = DiffableMetadataSourceSnapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(metadataItemList)
        diffableMetadataSource.apply(snapshot)
    }
}

