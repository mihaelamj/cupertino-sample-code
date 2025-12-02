/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller responsible for the main view.
*/

import UIKit

/// This class displays a table view with entry points to the features of the app.
class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private static let reuseIdentifier = "entry"

    @IBOutlet private var tableView: UITableView!

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: animated)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MainViewController.reuseIdentifier, for: indexPath)

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Find Accommodation"
            cell.detailTextLabel?.text = "Check out our partners for a great deal!"
        case 1:
            cell.textLabel?.text = "After Hours"
            cell.detailTextLabel?.text = "Find the best places in San Jose."
        case 2:
            cell.textLabel?.text = "Concert in the Park"
            cell.detailTextLabel?.text = "Wednesday night at 8 PM. Be there!"
        default:
            cell.textLabel?.text = ""
            cell.detailTextLabel?.text = ""
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "showAccommodation", sender: self)
        case 1:
            performSegue(withIdentifier: "showAfterHours", sender: self)
        case 2:
            performSegue(withIdentifier: "showEvent", sender: self)
        default:
            return
        }
    }
}
