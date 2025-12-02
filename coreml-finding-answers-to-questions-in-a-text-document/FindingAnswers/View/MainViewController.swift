/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Table view controller that manages content for the main table view.
*/

import UIKit

class MainViewController: UITableViewController {
    static private let exampleText = "The quick brown fox jumps over the lethargic dog."
    
    var detailViewController: DetailViewController?
    var objects: [Document] = [
        Document(title: "Fox & Dog", body: MainViewController.exampleText)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.leftBarButtonItem = editButtonItem

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        
        if let split = splitViewController {
            detailViewController = split.viewControllers.last as? DetailViewController
        }
        // Select the first row to show the example.
        tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .none)
        performSegue(withIdentifier: "showDetail", sender: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    @objc
    func insertNewObject(_ sender: Any) {
        objects.insert(Document(), at: 0)
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [indexPath], with: .automatic)
    }

    // MARK: - Segues
    
    @IBSegueAction func makeDetailViewController(coder: NSCoder, sender: Any?, segueIdentifier: String?) -> UINavigationController? {
        guard let navigationController = UINavigationController(coder: coder) else {
            print("Unable to create UINavigationController")
            return nil
        }
        
        guard let indexPath = tableView.indexPathForSelectedRow else {
            print("Unable to determine the selected row")
            return nil
        }
        
        guard let detailController = navigationController.topViewController as? DetailViewController else {
            print("The UINavigationController's topViewController is not a DetailViewController")
            return nil
        }
        
        detailController.detailItem = objects[indexPath.row]
        detailController.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        detailController.navigationItem.leftItemsSupplementBackButton = true
        
        return navigationController
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return objects.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        let object = objects[indexPath.row]
        cell.textLabel!.text = object.title
        return cell
    }

    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            objects.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}
