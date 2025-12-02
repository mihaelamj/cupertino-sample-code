/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The window controller for managing the UI content.
*/

import Cocoa

class WindowController: NSWindowController, NSUserInterfaceValidations {
    // MARK: - Properties
    
    fileprivate var resourceFile = ProductIdentifiers()
    fileprivate var mainViewController: MainViewController!
    
    // MARK: - Window Life Cycle
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        guard let window = window else { fatalError("\(Messages.windowDoesNotExist)") }
        guard let viewController = window.contentViewController as? MainViewController else { fatalError("\(Messages.viewControllerDoesNotExist)") }
        
        mainViewController = viewController
        
        // Check whether the user has authorization to make purchases. Proceed if they do. Display an alert, otherwise.
        if StoreObserver.shared.isAuthorizedForPayments {
            // Refresh the UI if the resource file containing the product identifiers exists. Show a message, otherwise.
            guard let identifiers = resourceFile.identifiers else {
                // Warn the user that the resource file can’t be found.
                mainViewController.reloadViewController(.messages, with: "\(resourceFile.wasNotFound)")
                return
            }
            
            // Refresh the UI if the resource file containing the product identifiers exists. Show a message, otherwise.
            if !identifiers.isEmpty {
                mainViewController.reloadViewController(.products)
            } else {
                // Warn the user that the resource file doesn’t contain anything.
                mainViewController.reloadViewController(.messages, with: "\(resourceFile.isEmpty)")
            }
        } else {
            // Warn the user that they don’t have authorization to make purchases.
            mainViewController.reloadViewController(.messages, with: Messages.cannotMakePayments)
        }
    }
    
    // MARK: - Switches Between Products and Purchases Panes
    
    @IBAction fileprivate func showProducts(_ sender: NSToolbarItem) {
        guard ViewControllerNames(rawValue: sender.label) != nil else { fatalError("\(Messages.unknownToolbarItem)\(sender.label).") }
        mainViewController.reloadViewController(.products)
    }
    
    @IBAction func showPurchases(_ sender: NSToolbarItem) {
        guard ViewControllerNames(rawValue: sender.label) != nil else { fatalError("\(Messages.unknownToolbarItem)\(sender.label).") }
        mainViewController.reloadViewController(.purchases)
    }
    
    // MARK: - NSUserInterfaceValidations
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        let identifiers = resourceFile.identifiers
        
        if item.action == #selector(WindowController.showProducts(_:)) {
            return StoreObserver.shared.isAuthorizedForPayments && (identifiers != nil && !(identifiers!.isEmpty))
        } else if item.action == #selector(WindowController.showPurchases(_:)) {
            return StoreObserver.shared.isAuthorizedForPayments
        }
        return false
    }
}

