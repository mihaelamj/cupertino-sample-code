/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Detail view controller portion of UISplitViewController.
*/

import UIKit

// Custom view subclass for contextual menus.
class ResponsiveView: UIView {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

// MARK: -

protocol DetailItemDelegate: NSObjectProtocol {
    func performCutAction()
    func performCopyAction()
    func performPasteAction()
    func performDeleteAction()
    func didUpdateItem(_ item: AnyModelItem)
}

// MARK: -

class DetailViewController: UIViewController {
        
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var detailDescriptionView: UIView!
    
    weak var detailItemDelegate: DetailItemDelegate?
    
    var detailItem: AnyModelItem? {
        didSet {
            // Update the view.
            configureView()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        configureView()
           
        /** Add a contextual menu to this view controller's view, so the user can either tap and hold (iPadOS), or control-click (macOS),
            to access the Copy, Copy, Paste, Delete, Rename, Share and Print operations.
         */
        let interaction = UIContextMenuInteraction(delegate: self)
        self.view.addInteraction(interaction)
        
        detailDescriptionView.layer.cornerRadius = 10
        
        // Listen for preference changes for the view's background color.
        backgroundColorObserver = UserDefaults.standard.observe(\.nameColorKey,
                                                                options: [.initial, .new],
                                                                changeHandler: { (defaults, change) in
            self.updateView()
        })

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        #if targetEnvironment(macCatalyst)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        #endif
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if detailItem != nil {
            detailDescriptionLabel?.text = detailItem?.description
        } else {
            detailDescriptionLabel?.text = NSLocalizedString("noselection", comment: "")
        }
    }
    
// MARK: - Printing
       
    // Returns a text print formatter for the current detail item.
    func itemToPrintFormatter() -> UISimpleTextPrintFormatter {
        var returnFormatter: UISimpleTextPrintFormatter!
        
        if let itemToPrint = detailItem?.description {
            let printString = NSMutableAttributedString(string: itemToPrint)
            
            // Use a special font for printing.
            let fontAttribute = [NSAttributedString.Key.font: UIFont(name: "Helvetica", size: 32)]
            printString.setAttributes(fontAttribute as [NSAttributedString.Key: Any],
                                      range: NSRange(location: 0, length: printString.length))
            
            // Use the preference color for printing.
            let viewColor = UserDefaults.standard.integer(forKey: DetailViewController.nameColorKey)
            if let preferredColor = AppDelegate.BackgroundColor(rawValue: viewColor) {
                let colorToUse = AppDelegate.backgroundColorValue(colorValue: preferredColor)
                let colorAttribute = [NSAttributedString.Key.foregroundColor: colorToUse]
                printString.setAttributes(colorAttribute as [NSAttributedString.Key: Any],
                                          range: NSRange(location: 0, length: printString.length))
            }

            returnFormatter = UISimpleTextPrintFormatter(attributedText: printString)
            returnFormatter.perPageContentInsets = UIEdgeInsets(top: 40, left: 40, bottom: 40, right: 40)
            returnFormatter.startPage = 0
        }
            
        return returnFormatter
    }
    
    func printItem() {
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "Print Item"
        printInfo.outputType = .grayscale
        
        let printController = UIPrintInteractionController()
        printController.printInfo = printInfo
        
        let formatter = itemToPrintFormatter()
        printController.printFormatter = formatter
        printController.present(animated: true, completionHandler: { (completion, success, error) -> Void in
            if success {
                // Printed OK.
            } else {
                // Print cancelled.
            }
        })
    }

// MARK: - Preferred Background Color
    
    // Key for obtaining the preference view color.
    static let nameColorKey = "nameColorKey"

    // Key-value-observing for preference changes.
    var backgroundColorObserver: NSKeyValueObservation?
    
    // Update the detail view's background color.
    func updateView() {
        let viewColor = UserDefaults.standard.integer(forKey: DetailViewController.nameColorKey)
        if let colorValue = AppDelegate.BackgroundColor(rawValue: viewColor) {
            detailDescriptionView.backgroundColor = AppDelegate.backgroundColorValue(colorValue: colorValue)
        }
    }
    
}

// MARK: - User Defaults

// Extend UserDefaults for quick access to nameColorKey.
extension UserDefaults {
    
    @objc dynamic var nameColorKey: Int {
        return integer(forKey: DetailViewController.nameColorKey)
    }
    
}

// MARK: - UIContextMenuInteractionDelegate

extension DetailViewController: UIContextMenuInteractionDelegate {
    
    func renameDetailedItem() {
        let message = NSLocalizedString("RenameMessage", comment: "")
        let cancelButtonTitle = NSLocalizedString("CancelTitle", comment: "")
        let destructiveButtonTitle = NSLocalizedString("RenameTitle", comment: "")
        
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancelButtonTitle, style: .cancel) { _ in }
        let destructiveAction = UIAlertAction(title: destructiveButtonTitle, style: .destructive) { _ in
            if let detailItem = self.detailItem {
                let textField = alertController.textFields![0] as UITextField
                self.detailItem!.text = textField.text!
                self.detailItem!.date = nil
            
                // Tell our delegate (PrimaryViewController) the item has been renamed.
                self.detailItemDelegate?.didUpdateItem(detailItem)
            }
        }
        
        // Add the text field for renaming the detailed item.
        var textDidChangeObserver: NSObjectProtocol?
        alertController.addTextField { [self] textField in
            
            textField.text = self.detailDescriptionLabel.text
            
            // Listen for changes to the text field's text. Enable the destructive action button only when the user has entered some text.
            textDidChangeObserver = NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: textField, queue: OperationQueue.main) { (notification) in
                    if let textField = notification.object as? UITextField {
                        if let textContent = textField.text {
                            destructiveAction.isEnabled = !textContent.isEmpty
                        }
                    }
            }
        }
          
        // Add the rename and cancel button actions.
        alertController.addAction(destructiveAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true) {
            if let observer = textDidChangeObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
    }
    
    // Called by the context menu Share menu item.
    func shareDetailedItem() {
        if let content = self.detailItem?.description {
            // Share operation will consist of print and share.
            
            // For iOS: Printing is offered the share operation.
            // For macOS: Printing is offered from the Print menu item under File.
            #if targetEnvironment(macCatalyst)
            
            // For macOS, skip adding Print to this context menu.
            // Instead, printing will be in the Print menu item under File.
            
            let activityItems = [content] as [Any]
            
            #else
            
            // For iOS, activity items will be both: Print and Share for the detail item content.
            let printItem = itemToPrintFormatter()
            let activityItems = [content, printItem] as [Any]
            
            #endif
            
            // Present UIActivityViewController anchored from the detail view label.
            let activityViewController =
                UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            activityViewController.popoverPresentationController?.sourceView = self.detailDescriptionLabel
            activityViewController.popoverPresentationController?.sourceRect = self.detailDescriptionLabel.bounds
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    // Build the contextual menu for this detailed item.
    func contextMenuActions() -> [UIMenuElement] {
        // Actions for the contextual menu.
        let cutAction = UIAction(title: NSLocalizedString("CutTitle", comment: ""),
                                   image: UIImage(systemName: "doc.on.doc"),
                                   identifier: UIAction.Identifier(rawValue: "com.example.apple-samplecode.menus.cut")) { action in
            // Perform the Cut action, by copying the detail label string.
            self.detailItemDelegate!.performCutAction()
        }
        
        let copyAction = UIAction(title: NSLocalizedString("CopyTitle", comment: ""),
                                   image: UIImage(systemName: "doc.on.doc"),
                                   identifier: UIAction.Identifier(rawValue: "com.example.apple-samplecode.menus.copy")) { action in
            // Perform the Copy action by copying the detail label string.
            self.detailItemDelegate!.performCopyAction()
        }
         
        let pasteAction = UIAction(title: NSLocalizedString("PasteTitle", comment: ""),
                                   image: UIImage(systemName: "doc.on.doc"),
                                   identifier: UIAction.Identifier(rawValue: "com.example.apple-samplecode.menus.paste")) { action in
            // Perform the Paste action by pasting string contents of the pasteboard.
            self.detailItemDelegate!.performPasteAction()
        }
        
        let deleteAction = UIAction(title: NSLocalizedString("DeleteTitle", comment: ""),
                                   image: UIImage(systemName: "doc.on.doc"),
                                   identifier: UIAction.Identifier(rawValue: "com.example.apple-samplecode.menus.delete")) { action in
            // Perform the Delete action by deleting the selected item.
            self.detailItemDelegate!.performDeleteAction()
        }
        
        let renameAction = UIAction(title: NSLocalizedString("RenameTitle", comment: ""),
                                    image: UIImage(systemName: "square.and.pencil"),
                                    identifier: UIAction.Identifier(rawValue: "com.example.apple-samplecode.menus.rename")) { action in
            // Perform the Rename action with a UIAlertController.
            self.renameDetailedItem()
        }
         
        let shareAction = UIAction(title: NSLocalizedString("ShareTitle", comment: ""),
                                    image: UIImage(systemName: "square.and.arrow.up"),
                                    identifier: UIAction.Identifier(rawValue: "com.example.apple-samplecode.menus.share")) { action in
            // Perform the Share action with a UIActivityViewController (which will offer sharing and printing the data).
            self.shareDetailedItem()
        }
        
        // The Rename and Share commands will be separated from edit actions.
        let renameGroup = UIMenu(title: "", options: .displayInline, children: [renameAction])
        let shareGroup = UIMenu(title: "", options: .displayInline, children: [shareAction])
        var actions = [cutAction, copyAction, pasteAction, deleteAction, renameGroup, shareGroup]
        
        #if targetEnvironment(macCatalyst)
        // For Mac Catalyst, include Print action, but for iOS, this will be found in the Share menu item.
        let printAction = UIAction(title: NSLocalizedString("PrintTitle", comment: ""),
                                    image: UIImage(systemName: "square.and.arrow.up"),
                                    identifier: UIAction.Identifier(rawValue: "com.example.apple-samplecode.menus.share")) { action in
            // Perform the Print action.
            self.printItem()
        }
        
        let printGroup = UIMenu(title: "", options: .displayInline, children: [printAction])
        
        actions.append(printGroup)
        #endif
        
        return actions
    }
    
    // Open a contextual menu from this view.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        /** Allow for contextual menu for the rest of the detail view.
            Mac Catalyst: The user control-clicks or right-clicks on the detail view controller's content.
            iOS: The user taps and holds the detail view controller's content.
        */
        let configuration =
            UIContextMenuConfiguration(identifier: NSString(""), previewProvider: nil) { (elements) -> UIMenu? in
                guard self.detailItem != nil else { return nil }

                let menu = UIMenu(title: NSLocalizedString("ContextMenuTitle", comment: ""),
                                  image: nil,
                                  identifier: UIMenu.Identifier("com.example.apple-samplecode.menus.detailContextMenu"),
                                  options: [],
                                  children: self.contextMenuActions())
                return menu
            }
        return configuration
    }

    // Make a custom highlight preview for this detail view controller, using the detailDescriptionLabel as the preview.
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                                previewForHighlightingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        let parameters = UIPreviewParameters()
        parameters.backgroundColor = UIColor.clear
        let visibleRect = detailDescriptionLabel.bounds.insetBy(dx: 4, dy: -10)
        let visiblePath = UIBezierPath(roundedRect: visibleRect, cornerRadius: 10.0)
        parameters.visiblePath = visiblePath
        return UITargetedPreview(view: detailDescriptionLabel, parameters: parameters)
    }
    
    override var activityItemsConfiguration: UIActivityItemsConfigurationReading? {
        get { detailItem } // In order to return this object, it needs to adopt UIActivityItemsConfigurationReading.
        set {
            super.activityItemsConfiguration = newValue
        }
    }
}
