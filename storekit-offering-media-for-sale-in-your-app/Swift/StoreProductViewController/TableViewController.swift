/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The table view controller for presenting the App Store when the user selects
 an iTunes product available for sale from its UI.
*/

import UIKit
import StoreKit

class TableViewController: UITableViewController {
    // MARK: - Properties
    
    var products = [Product]()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        products = fetchMedia()
    }
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "productID", for: indexPath)
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let item = products[indexPath.row]
        cell.textLabel?.text = item.title
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = products[indexPath.row]
        showStore(forProduct: item)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - TableViewController Extension

extension TableViewController {
    /// Fetch all the media products.
    func fetchMedia() -> [Product] {
        var result = [Product]()
        guard let url = Bundle.main.url(forResource: "Products", withExtension: "plist") else { return result }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            result = try decoder.decode([Product].self, from: data)
        } catch {
            print("Error: \(error)")
        }
        return result
    }
    
    /// Presents a page where users can purchase the specified `product` from the App Store.
    func showStore(forProduct product: Product) {
        
        var parametersDictionary = [SKStoreProductParameterITunesItemIdentifier: product.productIdentifier]
        
        /*
            Update `parametersDictionary` with the `campaignToken` and
            `providerToken` values if they exist and the specified `product`
            is an app.
        */
        if product.isApplication, !product.campaignToken.isEmpty, !product.providerToken.isEmpty {
            parametersDictionary[SKStoreProductParameterCampaignToken] = product.campaignToken
            parametersDictionary[SKStoreProductParameterProviderToken] = product.providerToken
        }
        
        // Create a store product view controller.
        let store = SKStoreProductViewController()
        store.delegate = self
        
        /*
           Attempt to load the selected product from the App Store. Display the
           store product view controller if successful. Print an error message,
           otherwise.
       */
        store.loadProduct(withParameters: parametersDictionary, completionBlock: {[unowned self] (result: Bool, error: Error?) in
            if result {
                self.present(store, animated: true, completion: {
                    print("The store view controller was presented.")
                })
            } else {
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }})
    }
}

// MARK: - SKStoreProductViewControllerDelegate

/// Extends `TableViewController` to implement SKStoreProductViewControllerDelegate.
extension TableViewController: SKStoreProductViewControllerDelegate {
    /// Use this method to dismiss the store view controller.
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.presentingViewController?.dismiss(animated: true, completion: {
            print("The store view controller was dismissed.")
        })
    }
}
