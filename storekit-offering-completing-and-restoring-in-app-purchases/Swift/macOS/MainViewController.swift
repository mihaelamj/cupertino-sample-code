/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller for managing products available for sale, invalid product
 identifiers, purchases, and messages.
*/

import Cocoa
import StoreKit

class MainViewController: NSViewController {
    // MARK: - Properties
    
    @IBOutlet weak fileprivate var popUpMenu: NSPopUpButton!
    @IBOutlet weak fileprivate var stackView: NSStackView!
    @IBOutlet weak fileprivate var containerView: NSView!
    
    fileprivate var utility = Utilities()
    fileprivate var purchaseType: SectionType = .purchased
    fileprivate var storeResponse = [Section]()
    
    fileprivate var contentType: ViewControllerNames = .products {
        didSet {
            purchaseType = ((contentType == .purchases) && utility.restoreWasCalled) ? .restored : .purchased
        }
    }
    
    // MARK: - Instantiate View Controllers
    
    fileprivate lazy var availableProducts: AvailableProducts = {
        let identifier: NSStoryboard.SceneIdentifier = ViewControllerIdentifiers.availableProducts
        guard let controller = storyboard?.instantiateController(withIdentifier: identifier) as? AvailableProducts
            else { fatalError("\(Messages.unableToInstantiateAvailableProducts)") }
        return controller
    }()
    
    fileprivate lazy var invalidIdentifiers: InvalidProductIdentifiers = {
        let identifier: NSStoryboard.SceneIdentifier = ViewControllerIdentifiers.invalidProductdentifiers
        guard let controller = storyboard?.instantiateController(withIdentifier: identifier) as? InvalidProductIdentifiers
            else { fatalError("\(Messages.unableToInstantiateInvalidProductIds)") }
        return controller
    }()
    
    fileprivate lazy var messagesViewController: MessagesViewController = {
        let identifier: NSStoryboard.SceneIdentifier = ViewControllerIdentifiers.messages
        guard let controller = storyboard?.instantiateController(withIdentifier: identifier) as? MessagesViewController
            else { fatalError("\(Messages.unableToInstantiateMessages)") }
        return controller
    }()
    
    fileprivate lazy var purchasesDetails: PurchasesDetails = {
        let identifier: NSStoryboard.SceneIdentifier = ViewControllerIdentifiers.purchases
        guard let controller = storyboard?.instantiateController(withIdentifier: identifier) as? PurchasesDetails
            else { fatalError("\(Messages.unableToInstantiateMessages)") }
        return controller
    }()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        disableUI()
        
        StoreManager.shared.delegate = self
        StoreObserver.shared.delegate = self
    }
    
    // MARK: - Populate Pop-up Menu
    
    /// The system uses this to update the UI with available products, invalid identifiers, purchases, and restored purchases.
    @IBAction fileprivate func popUpMenuDidChangeValue(_ sender: NSPopUpButton) {
        guard let title = sender.titleOfSelectedItem, let type = SectionType(rawValue: title) else { return }
        
        switch type {
        case .availableProducts:
            if let section = Section.parse(storeResponse, for: .availableProducts), let items = section.elements as? [SKProduct], !items.isEmpty {
                switchToViewController(availableProducts)
                availableProducts.reload(with: items)
            }
        case .invalidProductIdentifiers:
            if let section = Section.parse(storeResponse, for: .invalidProductIdentifiers), let items = section.elements as? [String],
                !items.isEmpty {
                switchToViewController(invalidIdentifiers)
                invalidIdentifiers.reload(with: items)
            }
        case .purchased: utility.restoreWasCalled = false
        case .restored: utility.restoreWasCalled = true
        default: break
        }
        
        if contentType == .purchases {
            let data = utility.dataSourceForPurchasesUI
            purchaseType = type
            if let transactions = Section.parse(data, for: type)?.elements as? [SKPaymentTransaction] {
                purchasesDetails.reload(with: transactions)
            }
        }
    }
    
    /// Updates the pop-up menu with the given items and selects the item with the specified title.
    fileprivate func reloadPopUpMenu(with items: [String], andSelectItemWithTitle title: String) {
        popUpMenu.removeAllItems()
        
        if !items.isEmpty {
            popUpMenu.addItems(withTitles: items)
            popUpMenu.selectItem(withTitle: title)
        }
    }
    
    // MARK: - Handle Restored Transactions
    
    /// Handles successful restored transactions. Switches to the Purchases view.
    fileprivate func handleRestoredSucceededTransaction() {
        utility.restoreWasCalled = true
        contentType = .purchases
        reloadViewController(.purchases)
    }
    
    // MARK: - Switching Between View Controllers
    
    /// Adds a subview to the container.
    fileprivate func addPrimaryViewController(_ viewController: NSViewController) {
        addChild(viewController)
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        var newViewControllerFrame = viewController.view.frame
        newViewControllerFrame.size.height = containerView.frame.height
        newViewControllerFrame.size.width = containerView.frame.width
        viewController.view.frame = newViewControllerFrame
        containerView.addSubview(viewController.view)
        
        NSLayoutConstraint.activate([viewController.view.topAnchor.constraint(equalTo: containerView.topAnchor),
                                     viewController.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                                     viewController.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                                     viewController.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)])
    }
    
    /// Removes a subview from the container.
    fileprivate func removePrimaryViewController(_ viewController: NSViewController) {
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    /// Removes all subviews from the container.
    fileprivate func removeAllPrimaryChildViewControllers() {
        for child in children {
            removePrimaryViewController(child)
        }
    }
    
    // MARK: - Configure UI
    
    /// Hides the pop-up button and the status message.
    fileprivate func disableUI() {
        if self.isViewLoaded {
            popUpMenu.hide()
            self.view.layoutSubtreeIfNeeded()
        }
    }
    
     /// Displays the specified view controller.
     fileprivate func switchToViewController(_ viewController: NSViewController) {
        removeAllPrimaryChildViewControllers()
        addPrimaryViewController(viewController)
    }
    
    /// Reloads the UI of the specified view controller.
    func reloadViewController(_ viewController: ViewControllerNames, with message: String = String()) {
        disableUI()
        
        contentType = viewController
        var menu = [String]()
        var selectedItem = String()
        let resourceFile = ProductIdentifiers()
        
        if viewController == .messages {
            switchToViewController(messagesViewController)
            messagesViewController.message = message
        } else if viewController == .products {
            guard let identifiers = resourceFile.identifiers else { return }
            
            popUpMenu.show()
            self.view.layoutSubtreeIfNeeded()
            selectedItem = SectionType.invalidProductIdentifiers.description
            menu.append(selectedItem)
            
            switchToViewController(invalidIdentifiers)
            invalidIdentifiers.reload(with: identifiers)
            storeResponse = [Section(type: .invalidProductIdentifiers, elements: identifiers)]
            // Fetch product information.
            StoreManager.shared.startProductRequest(with: identifiers)
        } else if viewController == .purchases {
            let data = utility.dataSourceForPurchasesUI
            
            if !data.isEmpty {
                popUpMenu.show()
                selectedItem = purchaseType.description
                menu = data.compactMap { (item: Section) in item.type.description }
                
                guard let transactions = Section.parse(data, for: purchaseType)!.elements as? [SKPaymentTransaction] else { return }
                
                switchToViewController(purchasesDetails)
                purchasesDetails.reload(with: transactions)
            } else {
                switchToViewController(messagesViewController)
                messagesViewController.message = "\(Messages.noPurchasesAvailable)\n\(Messages.useStoreRestore)"
            }
        }
        
        if !menu.isEmpty && !selectedItem.isEmpty {
            reloadPopUpMenu(with: menu, andSelectItemWithTitle: selectedItem)
        }
    }
}

// MARK: - StoreManagerDelegate

/// Extends MainViewController to conform to StoreManagerDelegate.
extension MainViewController: StoreManagerDelegate {
    func storeManagerDidReceiveResponse(_ response: [Section]) {
        if !response.isEmpty {
            var selectedItem = String()
            contentType = .products
            storeResponse = response
        
            let menu: [String] = response.compactMap { (item: Section) in item.type.description }
            
            if let section = Section.parse(response, for: .invalidProductIdentifiers),
                let items = section.elements as? [String] {
                selectedItem = SectionType.invalidProductIdentifiers.description
                switchToViewController(invalidIdentifiers)
                invalidIdentifiers.reload(with: items)
            }
            
            if let section = Section.parse(response, for: .availableProducts),
                let items = section.elements as? [SKProduct] {
                selectedItem = SectionType.availableProducts.description
                switchToViewController(availableProducts)
                availableProducts.reload(with: items)
            }
            reloadPopUpMenu(with: menu, andSelectItemWithTitle: selectedItem)
        }
    }
    
    func storeManagerDidReceiveMessage(_ message: String) {
        reloadViewController(.messages, with: message)
    }
}

// MARK: - StoreObserverDelegate

/// Extends MainViewController to conform to StoreObserverDelegate.
extension MainViewController: StoreObserverDelegate {
    func storeObserverDidReceiveMessage(_ message: String) {
        reloadViewController(.messages, with: message)
    }
    
    func storeObserverRestoreDidSucceed() {
        handleRestoredSucceededTransaction()
    }
}

