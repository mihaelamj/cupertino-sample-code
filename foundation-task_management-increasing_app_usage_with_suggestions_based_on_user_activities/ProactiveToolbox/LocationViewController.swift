/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The `LocationViewController` shows either the selected location from the `SearchViewController`,
 or the restored user activity location from the app invocation.
 The view reports the location it was created with as the current `NSUserActivity`.
*/

import UIKit
import MapKit
import CoreSpotlight
import os.log
import Intents

class LocationViewController: UITableViewController {

    @IBOutlet weak var placeAddressLabel: UILabel!
    @IBOutlet weak var placePhoneLabel: UILabel!
    @IBOutlet weak var placeWebsiteLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!

    var mapItem: MKMapItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDisplayedData()
    }
    
    private func updateDisplayedData() {
        guard isViewLoaded, let mapItem = self.mapItem
            else { return }
        
        navigationItem.title = mapItem.name
        
        placeAddressLabel.text = mapItem.placemark.formattedAddress
        placePhoneLabel.text = mapItem.phoneNumber
        placeWebsiteLabel.text = mapItem.url?.absoluteString
        
        mapView.showAnnotations([mapItem.placemark], animated: true)
        
        configureUserActivity()
    }

    /// - Tag: configure_activity
    private func configureUserActivity() {
        let activity = NSUserActivity(activityType: "com.example.apple-samplecode.ProactiveToolbox.view-location")
        
        // The following properties enable the activity to be indexed in Search.
        activity.isEligibleForPublicIndexing = true
        activity.isEligibleForSearch = true
        activity.title = mapItem?.name
        activity.keywords = ["pizza"]
        
        // The following properties enable the activity to be used as a shortcut with Siri.
        activity.isEligibleForPrediction = true
        activity.suggestedInvocationPhrase = "Show my favorite pizzeria"
        
        // Enable sharing this location by telling Siri to "share this".
        activity.webpageURL = mapItem?.url
        
        // Set delegate
        activity.delegate = self
        activity.needsSave = true

        /*
         Use the `userActivity` property of `UIViewController`, which is defined in
         `UIResponder`. UIKit will automatically manage this user activity and
         make it current when the view controller is present in the view
         hierarchy.
         */
        userActivity = activity
    }
    
    @IBAction func openItemInMaps(_ sender: UIButton) {
        mapItem?.openInMaps(launchOptions: nil)
    }

    func restoreMapItem(_ mapItem: MKMapItem!, url: URL?, phoneNumber: String?) {
        self.mapItem = mapItem
        self.mapItem?.url = url
        self.mapItem?.phoneNumber = phoneNumber
        
        updateDisplayedData()
    }
}

extension LocationViewController: NSUserActivityDelegate {
    
    /// - Tag: update_activity
    override func updateUserActivityState(_ activity: NSUserActivity) {
        /*
         Provide a map item to be promoted throughout the system.
         This will automatically populate the `contentAttributeSet` property
         with all available location information, including coordinates,
         text address components, phone numbers, etc.
         */
        activity.mapItem = mapItem

        if let mapItem = self.mapItem {
            /*
             Provide just enough information in the `userInfo` dictionary to be able to restore state.
             The larger the dictionary, the longer it takes to deliver that payload and resume the activity.
             */
            var userInfo = [String: Any]()
            do {
                let data = try NSKeyedArchiver.archivedData(withRootObject: mapItem.placemark, requiringSecureCoding: true)
                userInfo["placemark"] = data
            } catch {
                os_log("Could not encode placemark data", type: .error)
            }

            if let phoneNumber = mapItem.phoneNumber {
                userInfo["phoneNumber"] = phoneNumber
            }
            
            activity.addUserInfoEntries(from: userInfo)
        }
        
        // Provide additional searchable attributes.
        activity.contentAttributeSet?.supportsNavigation = true
        activity.contentAttributeSet?.supportsPhoneCall = true
        activity.contentAttributeSet?.thumbnailData = #imageLiteral(resourceName: "pizza").pngData()
    }
}
