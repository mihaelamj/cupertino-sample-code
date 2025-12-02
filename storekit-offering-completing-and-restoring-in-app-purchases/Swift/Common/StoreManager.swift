/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that retrieves product information from the App Store.
*/

import StoreKit
import Foundation

class StoreManager: NSObject {
    // MARK: - Types
    
    static let shared = StoreManager()
    
    // MARK: - Properties
    
    /// Keeps track of all valid products. These products are available for sale in the App Store.
    fileprivate var availableProducts = [SKProduct]()
    
    /// Keeps track of all invalid product identifiers.
    fileprivate var invalidProductIdentifiers = [String]()
    
    /// Keeps a strong reference to the product request.
    fileprivate var productRequest: SKProductsRequest!
    
    /// Keeps track of all valid products (these products are available for sale in the App Store) and of all invalid product identifiers.
    fileprivate var storeResponse = [Section]()
    
    weak var delegate: StoreManagerDelegate?
    
    // MARK: - Initializer
    
    private override init() {}
    
    // MARK: - Request Product Information
    
    /// Starts the product request with the specified identifiers.
    func startProductRequest(with identifiers: [String]) {
        fetchProducts(matchingIdentifiers: identifiers)
    }
    
    /// Fetches information about your products from the App Store.
    fileprivate func fetchProducts(matchingIdentifiers identifiers: [String]) {
        // Create a set for the product identifiers.
        let productIdentifiers = Set(identifiers)
        
        // Initialize the product request with the above identifiers.
        productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productRequest.delegate = self
        
        // Send the request to the App Store.
        productRequest.start()
    }
    
    // MARK: - Helper Methods
    
    /// - returns: The existing product's title matching the specified product identifier.
    func title(matchingIdentifier identifier: String) -> String? {
        var title: String?
        guard !availableProducts.isEmpty else { return nil }
        
        // Search availableProducts for a product with a productIdentifier property that matches identifier. Return its localized title.
        let result = availableProducts.filter({ (product: SKProduct) in product.productIdentifier == identifier })
        
        if !result.isEmpty {
            title = result.first!.localizedTitle
        }
        return title
    }
    
    /// - returns: The existing product's title associated with the specified payment transaction.
    func title(matchingPaymentTransaction transaction: SKPaymentTransaction) -> String {
        let title = self.title(matchingIdentifier: transaction.payment.productIdentifier)
        return title ?? transaction.payment.productIdentifier
    }
}

// MARK: - SKProductsRequestDelegate

/// Extends StoreManager to conform to SKProductsRequestDelegate.
extension StoreManager: SKProductsRequestDelegate {
    /// Use this to get the App Store's response to your request and notify your observer.
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if !storeResponse.isEmpty {
            storeResponse.removeAll()
        }
        
        // Contains products with identifiers that the App Store recognizes. As such, they are available for purchase.
        if !response.products.isEmpty {
            availableProducts = response.products
        }
        
        // invalidProductIdentifiers contains all product identifiers that the App Store doesn’t recognize.
        if !response.invalidProductIdentifiers.isEmpty {
            invalidProductIdentifiers = response.invalidProductIdentifiers
        }
        
        if !availableProducts.isEmpty {
            storeResponse.append(Section(type: .availableProducts, elements: availableProducts))
        }
        
        if !invalidProductIdentifiers.isEmpty {
            storeResponse.append(Section(type: .invalidProductIdentifiers, elements: invalidProductIdentifiers))
        }
        
        if !storeResponse.isEmpty {
            DispatchQueue.main.async {
                self.delegate?.storeManagerDidReceiveResponse(self.storeResponse)
            }
        }
    }
}

// MARK: - SKRequestDelegate

/// Extends StoreManager to conform to SKRequestDelegate.
extension StoreManager: SKRequestDelegate {
    /// The system calls this when the product request fails.
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.delegate?.storeManagerDidReceiveMessage(error.localizedDescription)
        }
    }
}
