/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller showing a list of acts in a play.
*/

import UIKit

class ActsTableViewController: UITableViewController {
    
    var play: Play? {
        didSet {
            navigationItem.title = play?.title ?? "Acts"
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return play?.acts.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActCellIdentifier", for: indexPath)
        cell.textLabel?.text = play?.acts[indexPath.row].identifier
        return cell
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showScenes",
            let indexPath = tableView.indexPathForSelectedRow,
            let controller = segue.destination as? ScenesTableViewController {
            
            controller.act = play?.acts[indexPath.row]
        }
    }
}
