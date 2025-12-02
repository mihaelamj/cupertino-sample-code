/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience protocols.
*/

import Foundation

// MARK: - DiscloseView

protocol DiscloseView {
    func show()
    func hide()
}

// MARK: - EnableItem

protocol EnableItem {
    func enable()
    func disable()
}

// MARK: - StoreManagerDelegate

protocol StoreManagerDelegate: AnyObject {
    /// Provides the delegate with the App Store's response.
    func storeManagerDidReceiveResponse(_ response: [Section])
    
    /// Provides the delegate with the error that occurs during the product request.
    func storeManagerDidReceiveMessage(_ message: String)
}

// MARK: - StoreObserverDelegate

protocol StoreObserverDelegate: AnyObject {
    /// Tells the delegate that the restore operation was successful.
    func storeObserverRestoreDidSucceed()
    
    /// Provides the delegate with messages.
    func storeObserverDidReceiveMessage(_ message: String)
}

// MARK: - SettingsDelegate

protocol SettingsDelegate: AnyObject {
    /// Tells the delegate when the user requests the restoration of their purchases.
    func settingDidSelectRestore()
}
