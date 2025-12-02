/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller showing a list of scenes in an act.
*/

import UIKit

class ScenesTableViewController: UITableViewController {

    var act: Act? {
        didSet {
            navigationItem.title = act?.identifier ?? "Act"
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return act?.scenes.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SceneCellIdentifier", for: indexPath)
        cell.textLabel?.text = act?.scenes[indexPath.row].identifier
        return cell
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showScene",
            let indexPath = tableView.indexPathForSelectedRow,
            let controller = segue.destination as? SceneViewController {
            
            controller.scene = act?.scenes[indexPath.row]
        }
    }
}
