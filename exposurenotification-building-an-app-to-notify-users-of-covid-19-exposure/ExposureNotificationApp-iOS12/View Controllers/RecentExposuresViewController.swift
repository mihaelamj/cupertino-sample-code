/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A tableview for displaying recent exposures.
*/

import UIKit

class RecentExposuresViewController: UITableViewController {

    let reuseIdentifier = "recentExposuresCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Recent Exposures"
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LocalStore.shared.exposures.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let exposure = LocalStore.shared.exposures[indexPath.row]
        
        var cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        }
        
        cell?.textLabel?.text = "Possible Exposure"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        formatter.formattingContext = .dynamic
        
        let detailText = DateFormatter.localizedString(from: exposure.date, dateStyle: .long, timeStyle: .none)
        cell?.detailTextLabel?.text = detailText

        return cell!
    }
}
