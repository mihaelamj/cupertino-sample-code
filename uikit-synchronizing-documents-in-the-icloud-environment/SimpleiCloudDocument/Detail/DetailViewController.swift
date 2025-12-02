/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller class to show and edit a document.
*/

import UIKit
import Combine

class DetailViewController: UICollectionViewController {
    @IBOutlet var handleConflictsItem: UIBarButtonItem!
    private var fileURLSubscriber: AnyCancellable?
    var document: Document?
    
    lazy var spinner: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .gray
        indicator.hidesWhenStopped = true
        
        guard let superView = view.superview else {
            fatalError("The view controller view isn't in the view hierarchy yet.")
        }
        superView.addSubview(indicator)
        superView.bringSubviewToFront(indicator)
        indicator.center = CGPoint(x: superView.frame.size.width / 2, y: superView.frame.size.height / 2)

        return indicator
    }()

    lazy var plusCircelItem: ImageItem = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 40)
        let image = UIImage(systemName: "plus.circle", withConfiguration: configuration)!
        return ImageItem(name: "plus.circle", thumbnail: image)
    }()
    
    // When a user adds an image, this sample caches the image file locally until the user taps Done to save the document.
    // cacheFolderURL points to the cache folder.
    //
    // Return the cache folder. Create it if it doesn’t exist.
    // The system doesn’t purge the files in the cache folder when the app is running.
    //
    lazy var cacheFolder: URL = {
        var url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        url = url.appendingPathComponent("SimpleiCloudDocument", isDirectory: true)
        
        guard !FileManager.default.fileExists(atPath: url.path) else { return url }
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create the cache folder: \(error)")
        }
        return url
    }()
    
    lazy var diffableImageSource: DiffableImageSource! = {
        return DiffableImageSource(collectionView: collectionView) { (collectionView, indexPath, imageItem) -> ImageCVCell? in
            let cvCell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCVCell", for: indexPath)
            guard let cell = cvCell as? ImageCVCell else {
                fatalError("Failed to dequeue ImageCVCell. Check the cell reusable identifier in Main.storyboard.")
            }
            cell.delegate = self
            cell.imageView.image = imageItem.thumbnail
            if indexPath.item == collectionView.numberOfItems(inSection: 0) - 1, self.isEditing {
                cell.backgroundColor = .systemGray6
                cell.imageView.alpha = 1
                cell.deleteButton.alpha = 0
            } else {
                cell.imageView.alpha = self.isEditing ? 0.6 : 1
                cell.deleteButton.alpha = self.isEditing ? 1 : 0
            }
            return cell
        }
    }()
    
    // Remove all cached files by removing the cache folder and then creating an empty folder.
    //
    private func clearCacheFolder() {
        do {
            try FileManager.default.removeItem(atPath: cacheFolder.path)
        } catch {
            print("Failed to delete \(cacheFolder)\n\(error)")
        }
        // Recreate the folder for future use.
        do {
            try FileManager.default.createDirectory(at: cacheFolder, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Failed to create the cache folder: \(error)")
        }
    }
}

// MARK: - UIViewController overridable
//
extension DetailViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = editButtonItem
        navigationItem.rightBarButtonItem?.isEnabled = !(document == nil)
        
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [flexible, handleConflictsItem, flexible]
        navigationController?.isToolbarHidden = false
        
        // Set up sections. The collection view has only one section in this sample.
        //
        var snapshot = DiffableImageSourceSnapshot()
        snapshot.appendSections([0])
        diffableImageSource.apply(snapshot)
    }
    
    // Subscribe the keyboard notifications when the view is about to appear.
    //
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let document = document else { return }
        
        // Update the UI with the document content.
        // Users can rename the document using other apps like Files.
        // When that happens, UIDocument updates its fileURL automatically.
        // The subscription makes sure the view controller title updates accordingly.
        //
        fileURLSubscriber = document.publisher(for: \.fileURL).receive(on: DispatchQueue.main).sink() { url in
            self.title = url.lastPathComponent
        }
        
        // Observe .stateChangedNotification to update the UI, if necessary.
        NotificationCenter.default.addObserver(
            self, selector: #selector(Self.documentStateChanged(_:)),
            name: UIDocument.stateChangedNotification, object: document)
        
        // documentState eventually turns to .normal, which updates the collection view.
        spinner.startAnimating()
        document.open { _ in
            self.spinner.stopAnimating()
        }
    }

    // Clean up the view controller.
    // Close the document, if necessary, cancel the fileURL KVO subscription,
    // and remove the observation of any notification.
    //
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let document = document, !document.documentState.contains(.closed) {
            document.close { success in
                if !success {
                    print("Failed to close the document: \(document.fileURL)")
                }
                self.clearCacheFolder()
                self.document = nil
            }
        } else {
            clearCacheFolder()
            self.document = nil
        }
        fileURLSubscriber?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    // Edit session management.
    // editing == true: In an editing session, show plusCircelItem and the delete button.
    // editing == false: The editing is done. Restore the UI and save the document.
    //
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: false)
        
        var snapshot = diffableImageSource.snapshot()
        editing ? snapshot.appendItems([plusCircelItem]) : snapshot.deleteItems([plusCircelItem])
        diffableImageSource.apply(snapshot)
        snapshot.reloadSections([0])
        diffableImageSource.apply(snapshot)

        guard !editing, let document = document else { return }

        // Save the document.
        // Apps normally call `document.updateChangeCount(.done)` to let UIDocument do autosave.
        // This sample chooses to save the document immediately by calling the save method
        // because it has a save button specific for this task.
        //
        spinner.startAnimating()
        document.save(to: document.fileURL, for: .forOverwriting) { _ in
            self.spinner.stopAnimating()
        }
    }
}
