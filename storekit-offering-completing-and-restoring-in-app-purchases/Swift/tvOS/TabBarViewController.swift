/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The tab bar view controller for managing products available for sale, invalid
 product identifiers, purchases, and app settings.
*/

import UIKit
import StoreKit

class TabBarViewController: UITabBarController {
    // MARK: - Types
    
     fileprivate enum TabBarViewControllerItems: Int {
        case products, purchases, settings
    }
    
    // MARK: - Properties
    
    fileprivate var utility = Utilities()
    fileprivate var resourceFile = ProductIdentifiers()
    fileprivate var restoreWasCalled = false
    
    fileprivate lazy var products: Products = {
        guard let navigation = self.viewControllers?[TabBarViewControllerItems.products.rawValue] as? UINavigationController
            else { fatalError("\(Messages.unableToInstantiateNavigationController)") }
        
        guard let controller = navigation.topViewController as? Products else { fatalError("\(Messages.unableToInstantiateProducts)") }
        return controller
    }()
    
    fileprivate lazy var purchases: Purchases = {
        guard let navigation = self.viewControllers?[TabBarViewControllerItems.purchases.rawValue] as? UINavigationController
            else { fatalError("\(Messages.unableToInstantiateNavigationController)") }
        
        guard let controller = navigation.topViewController as? Purchases else { fatalError("\(Messages.unableToInstantiatePurchases)") }
        return controller
    }()
    
    fileprivate lazy var settings: Settings = {
        guard let navigation = self.viewControllers?[TabBarViewControllerItems.settings.rawValue] as? UINavigationController
            else { fatalError("\(Messages.unableToInstantiateNavigationController)") }
        
        guard let controller = navigation.topViewController as? Settings else { fatalError("\(Messages.unableToInstantiateSettings)") }
        return controller
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        StoreManager.shared.delegate = self
        StoreObserver.shared.delegate = self
        settings.delegate = self
    }
    
    // MARK: - Fetch Product Information
    
    /// Retrieves product information from the App Store.
    fileprivate func fetchProductInformation() {
        /*
         Check whether the user has authorization to make purchases. Proceed if they do.
         Display an alert, otherwise.
       */
        if StoreObserver.shared.isAuthorizedForPayments {
            let resourceFile = ProductIdentifiers()
            
            guard let identifiers = resourceFile.identifiers else {
                // Warn the user that the resource file can’t be found.
                alert(with: Messages.status, message: resourceFile.wasNotFound)
                return
            }
            
            if !identifiers.isEmpty {
                // Refresh the UI with identifiers to query.
                products.reload(with: [Section(type: .invalidProductIdentifiers, elements: identifiers)])
                
                // Fetch the product information.
                StoreManager.shared.startProductRequest(with: identifiers)
            } else {
                // Warn the user that the resource file doesn’t contain anything.
                alert(with: Messages.status, message: resourceFile.isEmpty)
            }
        } else {
            // Warn the user that they don’t have authorization to make purchases.
            alert(with: Messages.status, message: Messages.cannotMakePayments)
        }
    }
    
    // MARK: - Handle Restored Transactions
    
    /// Handles successful restored transactions. Switches to the Purchases tab.
    fileprivate func handleRestoredSucceededTransaction() {
        utility.restoreWasCalled = restoreWasCalled
        purchases.reload(with: utility.dataSourceForPurchasesUI)
        selectedIndex = 1
    }
    
    // MARK: - Display Alert
    
    /// Creates and displays an alert.
     fileprivate func alert(with title: String, message: String) {
        let alertController = utility.alert(title, message: message)
        self.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - UITabBarControllerDelegate

/// Extends TabBarViewController to conform to UITabBarControllerDelegate.
extension TabBarViewController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        return StoreObserver.shared.isAuthorizedForPayments
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        guard let index = tabBarController.viewControllers?.firstIndex(of: viewController) else {
            fatalError("\(Messages.unknownSelectedViewController)") }
        
        guard let item = TabBarViewControllerItems(rawValue: index) else { fatalError("\(Messages.unknownTabBarIndex)\(index)).") }
        
        switch item {
        case .products:
            restoreWasCalled = false
            fetchProductInformation()
        case .purchases:
            if let controller = (viewController as? UINavigationController)?.topViewController as? Purchases {
                utility.restoreWasCalled = restoreWasCalled
                controller.reload(with: utility.dataSourceForPurchasesUI)
            }
        case .settings: restoreWasCalled = false
        }
    }
}

// MARK: - SettingsDelegate

/// Extends TabBarViewController to conform to SettingsDelegate.
extension TabBarViewController: SettingsDelegate {
    func settingDidSelectRestore() {
        restoreWasCalled = true
    }
}

// MARK: - StoreManagerDelegate

/// Extends TabBarViewController to conform to StoreManagerDelegate.
extension TabBarViewController: StoreManagerDelegate {
    func storeManagerDidReceiveResponse(_ response: [Section]) {
        products.reload(with: response)
    }
    
    func storeManagerDidReceiveMessage(_ message: String) {
        alert(with: Messages.productRequestStatus, message: message)
    }
}

// MARK: - StoreObserverDelegate

/// Extends TabBarViewController to conform to StoreObserverDelegate.
extension TabBarViewController: StoreObserverDelegate {
    func storeObserverDidReceiveMessage(_ message: String) {
        alert(with: Messages.purchaseStatus, message: message)
    }
    
    func storeObserverRestoreDidSucceed() {
        handleRestoredSucceededTransaction()
    }
}
