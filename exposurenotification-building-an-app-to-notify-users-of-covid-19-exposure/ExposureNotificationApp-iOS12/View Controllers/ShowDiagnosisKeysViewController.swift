/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller for displaying diagnosis keys.
*/

import UIKit

class ShowDiagnosisKeysViewController: UITableViewController {

    let reuseIdentifier = "diagnosisKeysCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Diagnosis Keys on Server"
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
         return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Server.shared.diagnosisKeys.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let diagnosisKey = Server.shared.diagnosisKeys[indexPath.row]
        
        var cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        }
        
        cell?.textLabel?.text = diagnosisKey.keyData.reduce("") { $0 + String(format: "%02x", $1) }
        cell?.detailTextLabel?.text = String(diagnosisKey.rollingStartNumber)
        
        return cell!
    }
}
