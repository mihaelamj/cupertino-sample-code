/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Base class for handling a table view with images.
*/

import UIKit

class BaseTableViewTestViewController: UITableViewController {
    
    enum Section { case main }
    var dataSource: UITableViewDiffableDataSource<Section, Model>! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(TableViewCell.self, forCellReuseIdentifier: TableViewCell.reuseIdentifier)
        dataSource = UITableViewDiffableDataSource<Section, Model>(tableView: tableView) {
            (tableView: UITableView, indexPath: IndexPath, model: Model) -> UITableViewCell? in

            // Get a cell of the desired kind.
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: TableViewCell.reuseIdentifier,
                for: indexPath) as? TableViewCell else { fatalError("Cannot create new cell") }
            
            cell.textLabel?.text = model.name
            cell.imageView?.image = UIImage(named: model.name)
            return cell
        }
        
        // Set the Initial data.
        var snapshot = NSDiffableDataSourceSnapshot<Section, Model>()
        snapshot.appendSections([.main])
        let items = (0..<7).map { Model.createItem(index: $0) }
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}
