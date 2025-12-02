/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller for the view-based table view of images, using an NSScrubberImageItemView without subclassing.
*/

import Cocoa

class BackgroundImagesViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    static let imageScrubber = NSTouchBarItem.Identifier("com.TouchBarCatalog.TouchBarItem.imageScrubber")
    let scrubberBarCustomizationIdentifier = NSTouchBar.CustomizationIdentifier("com.TouchBarCatalog.scrubberBar")
    let itemViewIdentifier = NSUserInterfaceItemIdentifier("ImageItemViewIdentifier")
    
    var selectedItemIdentifier: NSTouchBarItem.Identifier = BackgroundImagesViewController.imageScrubber
    
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Listen for table view selection changes.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(BackgroundImagesViewController.selectionDidChange(_:)),
                                               name: NSTableView.selectionDidChangeNotification,
                                               object: tableView)
        
        // Load the pictures for the scrubber and table content.
        fetchPictureResources()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        view.window?.makeFirstResponder(view)
    }
    
   private func displayPhotos() {
        tableView.reloadData()
        
        touchBar = nil // Force update the NSTouchBar.
        
        progressIndicator.stopAnimation(self)
        progressIndicator.isHidden = true
        scrollView.isHidden = false
    }
    
    private func fetchPictureResources() {
        if PhotoManager.shared.loadComplete {
            displayPhotos()
        } else {
            // The PhotoManager hasn't loaded all the photos. This could take a while so show the progress indicator.
            PhotoManager.shared.delegate = self // To receive a notification when the photos finish loading.
            progressIndicator.isHidden = false
            scrollView.isHidden = true
            progressIndicator.startAnimation(self)
        }
    }
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return PhotoManager.shared.photos.count
    }
  
    // MARK: - NSTableViewDelegate
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let view = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else { return nil }
        
        if let imageDict = PhotoManager.shared.photos[row] as? [String: Any] {
            if let imageName = imageDict[PhotoManager.ImageNameKey] as? String {
                view.imageView?.image = NSImage(named: imageName)
            }
        }
        
        return view
    }
    
    // MARK: Notifications
    
    private func chooseImageWithIndex(index: Int) {
        guard let imageDict = PhotoManager.shared.photos[index] as? [String: Any] else { return }
        
        // Process the chosen image and dismiss as the popover.
        if let presentingViewController = presentingViewController as? TitleBarAccessoryViewController {
            if let backgroundViewController = presentingViewController.view.window?.contentViewController as? BackgroundViewController {
                if let imageName = imageDict[PhotoManager.ImageNameKey] as? String {
                    // Load the full image (not the thumbnail).
                    if let fullImage = NSImage(named: imageName) {
                        backgroundViewController.imageView.image = fullImage
                        presentingViewController.dismiss(self)
                    }
                }
            }
        }
    }
    
    @objc
    func selectionDidChange(_ notification: Notification) {
        // The user selected a particular background photo.
        guard 0...tableView.numberOfRows ~= tableView.selectedRow else { return }
        
        chooseImageWithIndex(index: tableView.selectedRow)
    }
    
    // MARK: NSTouchBarProvider
    
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = scrubberBarCustomizationIdentifier
        touchBar.defaultItemIdentifiers = [BackgroundImagesViewController.imageScrubber]
        touchBar.customizationAllowedItemIdentifiers = [BackgroundImagesViewController.imageScrubber]
        touchBar.principalItemIdentifier = BackgroundImagesViewController.imageScrubber
        
        return touchBar
    }
    
}

// MARK: - NSTouchBarDelegate

extension BackgroundImagesViewController: NSTouchBarDelegate {
    
    // The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        let scrubberItem: NSCustomTouchBarItem
        
        scrubberItem = NSCustomTouchBarItem(identifier: identifier)
        scrubberItem.customizationLabel = NSLocalizedString("Choose Photo", comment: "")
        
        let scrubber = NSScrubber()
        scrubber.register(NSScrubberImageItemView.self, forItemIdentifier: itemViewIdentifier)
        scrubber.mode = .free
        scrubber.selectionBackgroundStyle = .roundedBackground
        scrubber.delegate = self
        scrubber.dataSource = self
        scrubber.showsAdditionalContentIndicators = true
        scrubber.scrubberLayout = NSScrubberFlowLayout()
        
        scrubberItem.view = scrubber
        
        // Set the scrubber's width to be 400.
        let viewBindings: [String: NSView] = ["scrubber": scrubber]
        let hconstraints =
            NSLayoutConstraint.constraints(withVisualFormat: "H:[scrubber(400)]",
                                           options: [],
                                           metrics: nil,
                                           views: viewBindings)
        NSLayoutConstraint.activate(hconstraints)
        
        return scrubberItem
    }
    
}

// MARK: - PhotoManagerDelegate

extension BackgroundImagesViewController: PhotoManagerDelegate {

    // Refreshes the UI when the system loads all the photos.
    func didLoadPhotos(photos: [Any]) {
        displayPhotos()
    }
    
}

// MARK: - NSScrubberDataSource

extension BackgroundImagesViewController: NSScrubberDataSource, NSScrubberDelegate {
    
    func numberOfItems(for scrubber: NSScrubber) -> Int {
        return PhotoManager.shared.photos.count
    }
    
    // Scrubber is asking for a custom view representation for a particular item index.
    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        var returnItemView = NSScrubberItemView()
        if let itemView =
            scrubber.makeItem(withIdentifier: itemViewIdentifier, owner: nil) as? NSScrubberImageItemView {
            if index < PhotoManager.shared.photos.count {
                if let imageDict = PhotoManager.shared.photos[index] as? [String: Any] {
                    if let image = imageDict[PhotoManager.ImageKey] as? NSImage {
                        itemView.image = image
                    }
                }
            }
            returnItemView = itemView
        }
        return returnItemView
    }
    
    // Scrubber is asking for the size for a particular item.
    func scrubber(_ scrubber: NSScrubber, layout: NSScrubberFlowLayout, sizeForItemAt itemIndex: Int) -> NSSize {
        return NSSize(width: 50, height: 30)
    }
    
    // The user chose a particular image inside the scrubber.
    func scrubber(_ scrubber: NSScrubber, didSelectItemAt index: Int) {
        chooseImageWithIndex(index: index)
    }
    
}

