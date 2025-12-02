/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class to search for and store AppleStore instances.
*/

import Foundation
import MapKit

/**
 A class to search for and store Apple Store instances.
 */
class AppleStoreDirectory {
    
    private static let favoritesUbiquityStoreKey = "favoritesIdentifiers"
    private var stores: Set<AppleStore> = []
    
    /**
     A closure called after findAppleStores(in:) has found new stores and added them to the directory.
     The store directory executes this closure once per call to findAppleStores(in:) and delivers only
     AppleStore instances that weren’t previously in the directory.
     */
    var onStoresFound: ((Set<AppleStore>) -> Void)?
    
    /**
     Finds Apple Stores in the given region, using a natural language query. Adds any newly-found stores
     to the stores set, and then sends the new stores to the onStoresFound closure.
     - parameter region: The region to search. It may be more efficient (by having fewer false positives to
     discard) to limit the search to a region roughly the size of 1-2 administrative areas (such as states,
     provinces, or departments), rather than an entire country or continent.
     */
    func findAppleStores(in region: MKCoordinateRegion) {
        let request = MKLocalSearch.Request()
        // Note: adding "computer" to the query reduces false positives like "Apple Pie Café".
        request.naturalLanguageQuery = "Apple Store, computer"
        request.region = region
        let search = MKLocalSearch(request: request)
        search.start() {[weak self] responseOrNil, errorOrNil in
            if let response = responseOrNil {
                guard let self = self else { return }
                var newStores: Set<AppleStore> = []
                for mapItem in response.mapItems {
                    if let store = AppleStore(from: mapItem),
                        !self.stores.contains(store) {
                        newStores.insert(store)
                    }
                }
                self.stores.formUnion(newStores)
                self.onStoresFound?(newStores)
            }
        }
    }
    
    // MARK: - Favorites
    
    /**
     Indicates whether the user has marked the store as a favorite.
     - parameter store: An AppleStore to query.
     - returns: true if the store is a favorirte, false otherwise
     */
    func isFavorite(store: AppleStore) -> Bool {
        let dict = getFavoritesDictionaryFromUbiquity()
        return dict[store.url.lastPathComponent] != nil
    }
    
    /**
     Marks a given AppleStore's favorite status.
     - parameter isFavorite: A Bool indicating whether the store is a favorite (true) or not (false).
     - parameter store: The store whose favorite status is being set.
     */
    func setFavorite(_ isFavorite: Bool, for store: AppleStore) {
        var dict = getFavoritesDictionaryFromUbiquity()
        dict[store.url.lastPathComponent] = isFavorite ? store.url.absoluteString : nil
        storeFavoritesDictionaryInUbiquity(dict: dict)
    }
    
    // The store directory persists favorites as an iCloud dictionary with the last component of a
    // favorite store's URL path as the key, and the full URL's absolute string as the value, like this:
    // ["infiniteloop" : "http://www.apple.com/retail/infiniteloop"]
    // A store is a favorite if it is present in this dictionary, and is not a favorite if it is absent.
    private func getFavoritesDictionaryFromUbiquity() -> [String: String] {
        guard let dict = NSUbiquitousKeyValueStore.default.dictionary(forKey: AppleStoreDirectory.favoritesUbiquityStoreKey) else {
            NSUbiquitousKeyValueStore.default.set([:], forKey: AppleStoreDirectory.favoritesUbiquityStoreKey)
            return [:]
        }
        return dict as? [String: String] ?? [:]
    }
    
    private func storeFavoritesDictionaryInUbiquity(dict: [String: String]) {
        NSUbiquitousKeyValueStore.default.set(dict, forKey: AppleStoreDirectory.favoritesUbiquityStoreKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
}
