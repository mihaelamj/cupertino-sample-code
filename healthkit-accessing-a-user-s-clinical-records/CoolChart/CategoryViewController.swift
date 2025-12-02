/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that displays a list of the available FHIR resources.
*/

import Dispatch
import HealthKit
import UIKit

class CategoryViewController: UITableViewController {
    let displayItemProvider: DisplayItemProvider
    let healthStore: HKHealthStore
    let sampleType: HKSampleType
    
    var samples: [HKSample]?
    
    /// Initialize the data sources that populates the table view.
    required init(sampleType: HKSampleType, displayItemProvider: DisplayItemProvider, healthStore: HKHealthStore) {
        self.displayItemProvider = displayItemProvider
        self.healthStore = healthStore
        self.sampleType = sampleType
        
        super.init(style: .plain)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not supported")
    }
    
    /// Use HKSampleQuery to query the HealthKit store for samples by type.
    func queryForSamples() {
        let sortDescriptors = [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        let query = HKSampleQuery(sampleType: sampleType, predicate: nil, limit: 100, sortDescriptors: sortDescriptors) {(_, samplesOrNil, error) in
            DispatchQueue.main.async {
                guard let samples = samplesOrNil else {
                    self.handleError(error)
                    return
                }
                
                self.samples = samples
                self.tableView.reloadData()
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Make the view title cooler.
        title = coolify(sampleType.categoryDisplayName)
    }

    /// Perform a query for samples when the view appears.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        queryForSamples()
    }
    
    // MARK: - Table View
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection sectionIndex: Int) -> Int {
        return samples?.count ?? 0
    }
    
    func displayItem(for sampleOrNil: HKSample?) -> DisplayItem {
        guard let sample = sampleOrNil else {
            return DisplayItem.errorItem
        }
        
        return displayItemProvider.displayItem(for: sample)
    }

    /// Populate the table view cells with a title and subtitle that are defined by the displayItem.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellReuseIdentifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) ??
            UITableViewCell(style: .subtitle, reuseIdentifier: cellReuseIdentifier)

        let item = displayItem(for: samples?[indexPath.row])
        
        cell.textLabel?.text = item.title
        cell.detailTextLabel?.text = item.subtitle
        
        switch item.accessory {
        case .none:
            cell.accessoryType = .none
            cell.selectionStyle = .none
        case .disclosure:
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        }
        
        return cell
    }
    
    /// Reveal the FHIR JSON view when the user selects the row. The data is provided by the displayItemProvider protocol.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sample = samples?[indexPath.row], let detailController = displayItemProvider.detailViewController(for: sample) else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
    
        navigationController?.pushViewController(detailController, animated: true)
    }
    
    // MARK: -
    
    func handleError(_ error: Error?) {
        let alertController = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
}
