/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that presents detail information about a specified item.
*/

import UIKit
import HealthKit

class DetailViewController: UITableViewController, HealthStoreContainer {

    var healthStore: HKHealthStore!
    private var overviewStrings = [String]()
    private var detailStrings = [String]()
    
    // The item whose overview and detail information is shown.
    var detailableItem: Detailable? {
        didSet {
            // Configure the view when the detailable item is assigned.
            configureView()
        }
    }
    
    private func configureView() {
        if let item = detailableItem {
            // If you have an item get its overview and detail strings.
            overviewStrings.append(contentsOf: item.overviewStrings)
            item.getDetailStrings(healthStore) { (detailStrings) in
                DispatchQueue.main.async {
                    // Dispatch back to the main queue to reload the table after the detail strings are set.
                    self.detailStrings.append(contentsOf: detailStrings)
                    self.tableView.reloadData()
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // You have two sections: overview and details.
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Section 0 shows overview strings.
        // Section 1 shows detail strings.
        return section == 0 ? overviewStrings.count : detailStrings.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Overview" : "Details"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.textLabel!.text = (indexPath.section == 0 ? overviewStrings[indexPath.row] : detailStrings[indexPath.row])

        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false because you do not want the specified items to be editable.
        return false
    }
}

