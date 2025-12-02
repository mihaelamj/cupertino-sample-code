/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A `UIViewController` subclass that references the table view outlet and sets up the table view's data source.
*/

import UIKit

// This file isn't central to the sample. See `CustomCell.setUpLabelsAndConstraints()`, which is the main focus of this sample.

class ViewController: UIViewController {

    // MARK: - Properties
    
    @IBOutlet weak var tableView: UITableView!
    
    private let dataSource = CustomDataSource()
    
    // MARK: - UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()

        /*
         The view controller doesn't need to know about any custom cells that the table view will display.
         Instead, let the data source (which is responsible for creating them) register the cell(s) with the table view.
         */
        dataSource.registerCells(with: tableView)
        
        tableView.dataSource = dataSource
    }
}
