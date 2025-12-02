/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The table view controller responsible for displaying the filtered products as the user types in the search field.
*/

import UIKit

class ResultsTableController: UITableViewController {
    
    let tableViewCellIdentifier = "cellID"
    
    var filteredProducts = [Product]()
    
    @IBOutlet weak var resultsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let nib = UINib(nibName: "TableCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: tableViewCellIdentifier)
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredProducts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath)
        let product = filteredProducts[indexPath.row]
        
        cell.textLabel?.text = product.title
        
        let priceString = product.formattedIntroPrice()
        cell.detailTextLabel?.text = "\(priceString!) | \(product.yearIntroduced)"
        
        return cell
    }
}
