/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that provides purchase data and creates an alert.
*/

import StoreKit
#if os (macOS)
import Cocoa
#else
import UIKit
#endif

class Utilities {
    
    // MARK: - Properties
    
    /// Indicates whether the user initiates a restore.
    var restoreWasCalled: Bool
    
    /// - returns: An array for populating the Purchases view.
    var dataSourceForPurchasesUI: [Section] {
        var dataSource = [Section]()
        let purchased = StoreObserver.shared.purchased
        let restored = StoreObserver.shared.restored
        
        if restoreWasCalled && (!restored.isEmpty) && (!purchased.isEmpty) {
            dataSource.append(Section(type: .purchased, elements: purchased))
            dataSource.append(Section(type: .restored, elements: restored))
        } else if restoreWasCalled && (!restored.isEmpty) {
            dataSource.append(Section(type: .restored, elements: restored))
        } else if !purchased.isEmpty {
            dataSource.append(Section(type: .purchased, elements: purchased))
        }
        
        /*
           Display restored products only when the user taps the Restore button (iOS), or chooses Store > Restore (macOS) or "Restore all restorable
           purchases” (tvOS), and there are restored products.
        */
        restoreWasCalled = false
        return dataSource
    }
    
    // MARK: - Initialization
    
    init() {
        restoreWasCalled = false
    }
    
    // MARK: - Create Alert
    
    #if os (iOS) || os (tvOS)
    /// - returns: An alert with a specified title and message.
    func alert(_ title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: NSLocalizedString(Messages.okButton, comment: Messages.emptyString),
                                   style: .default, handler: nil)
        alertController.addAction(action)
        return alertController
    }
    #endif
}
