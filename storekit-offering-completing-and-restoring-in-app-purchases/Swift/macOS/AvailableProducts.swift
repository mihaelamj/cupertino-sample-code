/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The table view controller for presenting a list of products available for sale
 in the App Store.
*/

import Cocoa
import StoreKit

class AvailableProducts: PrimaryViewController {
    // MARK: - Types
    
    fileprivate enum CellIdentifiers: String {
        case product = "localizedTitle"
        case price = "price"
    }
    
    // MARK: - Refresh UI
    
    /// Refresh the UI with new products.
    func reload(with products: [SKProduct]) {
        data = products
        self.tableView.reloadData()
    }
    
    // MARK: - NSTableViewDelegate
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let tableColumn = tableColumn, let cell = tableView.makeView(withIdentifier: tableColumn.identifier, owner: nil) as? NSTableCellView,
            let product = data[row] as? SKProduct else { return nil }
        
        guard let cellIdentifier = CellIdentifiers(rawValue: tableColumn.identifier.rawValue) else { return nil }
        
        switch cellIdentifier {
        // Display the localized title of the product.
        case .product: cell.textField?.stringValue = product.localizedTitle
        case .price:
            // Display the product's price in the locale and currency that the App Store returns.
            if let formattedPrice = product.regularPrice {
                cell.textField?.stringValue = "\(formattedPrice)"
            }
        }
        return cell
    }
    
    /// Starts a purchase when the user taps a row.
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard tableView.selectedRow > -1 else { return }
        
        if let product = data[tableView.selectedRow] as? SKProduct {
            // Attempt to purchase the selected product.
            StoreObserver.shared.buy(product)
        }
    }
}
