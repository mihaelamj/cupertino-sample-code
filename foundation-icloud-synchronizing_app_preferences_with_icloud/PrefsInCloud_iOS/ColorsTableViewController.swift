/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller used for picking a color.
*/

import UIKit

class ColorsTableViewController: UITableViewController {
	
	var colorStrings = [String]()
    var selectedIndexPath: IndexPath?
	
	override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		
		// Check mark the current background color.
        if let cell = tableView.cellForRow(at: selectedIndexPath!) {
            cell.accessoryType = UITableViewCell.AccessoryType.checkmark
		}
    }

	// MARK: - UITableViewDataSource
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return colorStrings.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cellID", for: indexPath) as UITableViewCell
		cell.textLabel?.text = colorStrings[indexPath.row]
		return cell
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return NSLocalizedString("Available Background Colors:", comment: "")
	}
	
	// MARK: - UITableViewDelegate
	
	override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
		if let headerView = view as? UITableViewHeaderFooterView {
			headerView.textLabel?.textColor = .gray
			headerView.textLabel?.font = .boldSystemFont(ofSize: 12)
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		// Clean out the old checkmark state.
		for row in 0...colorStrings.count {
			let rowIndexPath = IndexPath(row: row, section: 0)
			if let cell = tableView.cellForRow(at: rowIndexPath) {
                cell.accessoryType = .none
			}
		}
		// Apply the new checkmark state.
		if let newCell = tableView.cellForRow(at: indexPath) {
            newCell.accessoryType = .checkmark
		}
		
		selectedIndexPath = indexPath
	}
}

