/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app delegate class.
*/

import Cocoa
import StoreKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserInterfaceValidations {
    // MARK: - Properties
    
    /// Indicates whether the app is registered with the payment queue.
    fileprivate var hasRegisteredForNotifications: Bool?
    
    // MARK: - Restore All Appropriate Purchases
    
    /// The system calls this when the user chooses InAppPurchases > Store > Restore in the app.
    @IBAction fileprivate func restore(_ sender: NSMenuItem) {
        // Calls StoreObserver to restore all restorable purchases.
        StoreObserver.shared.restore()
    }
    
    // MARK: - NSApplicationDelegate
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if let url = Bundle.main.appStoreReceiptURL, FileManager.default.fileExists(atPath: url.path) {
            if StoreObserver.shared.isAuthorizedForPayments {
                // Attach an observer to the payment queue.
                SKPaymentQueue.default().add(StoreObserver.shared)
                hasRegisteredForNotifications = true
            }
        } else {
            exit(173)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        if hasRegisteredForNotifications ?? false {
            // Remove the observer.
            SKPaymentQueue.default().remove(StoreObserver.shared)
        }
    }
    
    // MARK: - NSUserInterfaceValidations
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(AppDelegate.restore(_:)) {
            return StoreObserver.shared.isAuthorizedForPayments
        }
        return false
    }
}
