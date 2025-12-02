/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Demonstrates using a custom back button image with no back arrow and text.
*/

import UIKit

class CustomBackButtonViewController: UITableViewController {

    /// The data source is an array of city names, populated from Cities.json.
    var dataSource: CitiesDataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = CitiesDataSource()
        tableView.dataSource = dataSource
    }
}
