/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on NSUserActivity to declare userInfo keys and add convenience functions
 to encode and decode map regions and AppleStore metadata in the userInfo dictionary.
*/

import Foundation
import MapKit

/**
 An extension on NSUserActivity to add convenience functions to create MapKit types
 like MKCoordinateRegion from the activity's userInfo dictionary.
 */
extension NSUserActivity {
    
    // MARK: - Activity types
    public static let viewingActivityType = "com.example.apple-samplecode.HandoffMapViewer.map-viewing"
    public static let storeEditingActivityType = "com.example.apple-samplecode.HandoffMapViewer.store-editing"

    // MARK: - Map viewing activity
    // MARK: keys
    private static let regionCenterLatitudeKeyString =  "com.example.apple-samplecode.HandoffMapViewer.regionCenterLatitude"
    private static let regionCenterLongitudeKeyString =  "com.example.apple-samplecode.HandoffMapViewer.regionCenterLongitude"
    private static let regionSpanLatitudeKeyString =  "com.example.apple-samplecode.HandoffMapViewer.regionSpanLatitude"
    private static let regionSpanLongitudeKeyString =  "com.example.apple-samplecode.HandoffMapViewer.regionSpanLongitude"
    private static let viewingActivityRequiredKeys: Set<String> = [
        NSUserActivity.regionCenterLatitudeKeyString, NSUserActivity.regionCenterLongitudeKeyString,
        NSUserActivity.regionSpanLatitudeKeyString, NSUserActivity.regionSpanLongitudeKeyString
    ]
    
    // MARK: methods

    /**
     Creates an NSUserActivity with the "viewing" activity type and the appropriate required userInfo keys.
     */
    static func initForRegionViewing() -> NSUserActivity {
        let activity = NSUserActivity(activityType: viewingActivityType)
        activity.title = NSLocalizedString("Viewing Map", comment: "Viewng Map")
        activity.requiredUserInfoKeys = viewingActivityRequiredKeys
        activity.isEligibleForHandoff = true
        return activity
    }
    
    /**
     Updates the userInfo dictionary with the given region.
     - parameter region: The MKCoordinateRegion to store in the activity's userInfo.
     */
    func updateViewingRegion(_ region: MKCoordinateRegion) {
        let updateDict = [
            NSUserActivity.regionCenterLatitudeKeyString: region.center.latitude,
            NSUserActivity.regionCenterLongitudeKeyString: region.center.longitude,
            NSUserActivity.regionSpanLatitudeKeyString: region.span.latitudeDelta,
            NSUserActivity.regionSpanLongitudeKeyString: region.span.longitudeDelta]
        addUserInfoEntries(from: updateDict)
    }

    /**
     Gets the MKCoordinateRegion that this activity represents the viewing of.
     - returns: An MKCoordinateRegion constructed from the userInfo, or nil if the required
     key-value pairs missing or cannot be parsed.
     */
    func viewingRegion() -> MKCoordinateRegion? {
        guard let centerLatitude = userInfo?[NSUserActivity.regionCenterLatitudeKeyString] as? CLLocationDegrees,
            let centerLongitude = userInfo?[NSUserActivity.regionCenterLongitudeKeyString] as? CLLocationDegrees,
            let spanLatitude = userInfo?[NSUserActivity.regionSpanLatitudeKeyString] as? CLLocationDegrees,
            let spanLongitude = userInfo?[NSUserActivity.regionSpanLongitudeKeyString] as? CLLocationDegrees else {
                return nil
        }
        return MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centerLatitude,
                                                                 longitude: centerLongitude),
                                  span: MKCoordinateSpan(latitudeDelta: spanLatitude,
                                                         longitudeDelta: spanLongitude))
    }

    // MARK: - Apple Store editing activity
    // MARK: keys
    private static let storeEditingURLKey =  "com.example.apple-samplecode.HandoffMapViewer.storeEditingURL"
    private static let storeEditingLatitudeKey =  "com.example.apple-samplecode.HandoffMapViewer.storeEditingLatitude"
    private static let storeEditingLongitudeKey =  "com.example.apple-samplecode.HandoffMapViewer.storeEditingLongitude"
    private static let storeEditingRequiredKeys: Set<String> = [
        NSUserActivity.regionCenterLatitudeKeyString, NSUserActivity.regionCenterLongitudeKeyString,
        NSUserActivity.regionSpanLatitudeKeyString, NSUserActivity.regionSpanLongitudeKeyString,
        NSUserActivity.storeEditingURLKey, NSUserActivity.storeEditingLatitudeKey,
        NSUserActivity.storeEditingLongitudeKey
    ]

    // MARK: methods
    /**
     Creates an NSUserActivity with the "store editing" activity type and the appropriate required userInfo keys.
     */
    static func initForStoreEditing() -> NSUserActivity {
        let activity = NSUserActivity(activityType: storeEditingActivityType)
        activity.title = NSLocalizedString("Editing Store", comment: "Editing Store")
        activity.requiredUserInfoKeys = storeEditingRequiredKeys
        activity.isEligibleForHandoff = true
        return activity
    }
    
    /**
     Updates the userInfo dictionary with the given store's URL and coordinates.
     - parameter store: The AppleStore to store in the activity's userInfo.
     */
    func updateEditing(store: AppleStore) {
        let updateDict: [AnyHashable: Any] = [
            NSUserActivity.storeEditingURLKey: store.url.absoluteString,
            NSUserActivity.storeEditingLatitudeKey: store.placemark.coordinate.latitude,
            NSUserActivity.storeEditingLongitudeKey: store.placemark.coordinate.longitude
        ]
        addUserInfoEntries(from: updateDict)
    }
    
    /**
     Gets the AppleStore URL that this activity represents the editing of.
     - returns: A URL created from the userInfo, or nil if the required key-value pair is absent.
     */
    func editingStoreURL() -> URL? {
        guard let storeURLString = userInfo?[NSUserActivity.storeEditingURLKey] as? String,
            let storeURL = URL(string: storeURLString) else {
                return nil
        }
        return storeURL
    }
}
