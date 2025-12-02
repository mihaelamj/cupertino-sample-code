/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller showing the list of plays.
*/

import UIKit

class PlaysTableViewController: UITableViewController {
    var plays: [Play] {
        return PlayLibrary.shared.plays
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return plays.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PlayCellIdentifier", for: indexPath)
        cell.textLabel?.text = plays[indexPath.row].title
        return cell
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showActs",
            let indexPath = tableView.indexPathForSelectedRow,
            let nav = segue.destination as? UINavigationController,
            let controller = nav.topViewController as? ActsTableViewController {

            controller.play = plays[indexPath.row]
            controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        }
    }
}
