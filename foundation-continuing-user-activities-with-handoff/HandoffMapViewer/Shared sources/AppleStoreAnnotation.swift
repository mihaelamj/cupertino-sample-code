/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A map annotation for an Apple Store.
*/

import MapKit

/**
 A map annotation representing an Apple Store.
 */
class AppleStoreAnnotation: MKPointAnnotation {

    let store: AppleStore
    
    init (store: AppleStore) {
        self.store = store
        super.init()
        self.coordinate = store.placemark.coordinate
        self.title = store.name
    }
}
