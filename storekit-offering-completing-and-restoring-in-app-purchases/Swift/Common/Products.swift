/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The table view controller for presenting products available for sale
 in the App Store and invalid product identifiers.
*/

import UIKit
import StoreKit

class Products: BaseViewController {
    // MARK: - Types
    
    fileprivate struct CellIdentifiers {
        static let availableProduct = "available"
        static let invalidIdentifier = "invalid"
    }
    
    // MARK: - UITable​View​Data​Source
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = data[indexPath.section]
        
        if section.type == .availableProducts {
            return tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.availableProduct, for: indexPath)
        } else {
            return tableView.dequeueReusableCell(withIdentifier: CellIdentifiers.invalidIdentifier, for: indexPath)
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let section = data[indexPath.section]
        
        // If there are available products, show them.
        if section.type == .availableProducts, let content = section.elements as? [SKProduct] {
            let product = content[indexPath.row]
            
            // Show the localized title of the product.
            cell.textLabel!.text = product.localizedTitle
            
            // Show the product's price in the locale and currency that the App Store returns.
            if let formattedPrice = product.regularPrice {
                cell.detailTextLabel?.text = "\(formattedPrice)"
            }
        } else if section.type == .invalidProductIdentifiers, let content = section.elements as? [String] {
            // If there are invalid product identifiers, show them.
            cell.textLabel!.text = content[indexPath.row]
        }
    }
    
    /// Starts a purchase when the user taps an available product row.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = data[indexPath.section]
        
        // The user can only purchase available products.
        if section.type == .availableProducts, let content = section.elements as? [SKProduct] {
            let product = content[indexPath.row]
            
            // Attempt to purchase the tapped product.
            StoreObserver.shared.buy(product)
        }
    }
}
