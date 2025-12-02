/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary view controller for this sample.
*/

import Cocoa

extension NSPasteboard.PasteboardType {
    static let itemDragType = NSPasteboard.PasteboardType("com.mycompany.mydragdrop")
}

class ViewController: NSViewController {

    @IBOutlet weak var collectionView: NSCollectionView!
    
    var progressIndicator: NSProgressIndicator!
    
    // Queue you use to initially loading all the photos.
    var loaderQueue = OperationQueue()
    
    // Queue you use to read and writing file promises.
    var filePromiseQueue: OperationQueue = {
        let queue = OperationQueue()
        return queue
    }()
    
    // The temporary directory URL you use to accept file promises.
    lazy var destinationURL: URL = {
        let destinationURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("Drops")
        try? FileManager.default.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        return destinationURL
    }()

    enum Section {
        case main
    }
    var dataSource: NSCollectionViewDiffableDataSource<Section, PhotoItem>! = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupProgressIndicator()
        
        let itemNib = NSNib(nibNamed: "CollectionViewItem", bundle: nil)
        collectionView.register(itemNib, forItemWithIdentifier: CollectionViewItem.reuseIdentifier)
        collectionView.collectionViewLayout = createLayout()

        collectionView.delegate = self // Important for drag and drop.

        // Accept file promises from apps like Safari.
        collectionView.registerForDraggedTypes(
            NSFilePromiseReceiver.readableDraggedTypes.map { NSPasteboard.PasteboardType($0) })
        
        collectionView.registerForDraggedTypes([
            .fileURL, // Accept dragging of image file URLs from other apps.
            .itemDragType]) // Intra drag of row items numbers within the collection view.
           
        // Determine the kind of source drag originating from this app.
        // Note, if you want to allow your app to drag items to the Finder's trash can, add ".delete".
        collectionView.setDraggingSourceOperationMask([.copy, .delete], forLocal: false)
        
        loadPhotos()
    }
    
    func setupProgressIndicator() {
        // Create the progress indicator for asyncronous copies of promised files.
        progressIndicator = NSProgressIndicator(frame: NSRect())
        progressIndicator.controlSize = .regular
        progressIndicator.sizeToFit()
        progressIndicator.style = .spinning
        progressIndicator.isHidden = true
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressIndicator)
        // Center it to this view controller.
        NSLayoutConstraint.activate([
            progressIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            progressIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    func loadPhotos() {
        // Set up the async operation to load all the photos from the Pictures folder.
        let loadPhotosOperation = LoadPhotosOperation()
        
        // Set up the completion block so you know that all the photos are loaded.
        loadPhotosOperation.completionBlock = {
            // Finished loading all the photos.
            OperationQueue.main.addOperation {
                
                self.dataSource = self.makeDataSource()
                
                var snapshot = NSDiffableDataSourceSnapshot<Section, PhotoItem>()
                snapshot.appendSections([Section.main])
                
                if loadPhotosOperation.loadedImages.isEmpty {
                    Swift.debugPrint("No images found in the Pictures folder.")
                } else {
                    for photo in loadPhotosOperation.loadedImages {
                        // Set yourself to be notified when this photo's thumbnail image is ready.
                        photo.thumbnailDelegate = self
                    }
                    // Set the initial collection view data.
                    snapshot.appendItems(loadPhotosOperation.loadedImages)
                }

                self.dataSource.apply(snapshot, animatingDifferences: false)
            }
        }
        // Start the async load of all the photos.
        loaderQueue.addOperation(loadPhotosOperation)
    }
    
    private func createLayout() -> NSCollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(100.0),
                                              heightDimension: .absolute(100.0))
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(100.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        let layout = NSCollectionViewCompositionalLayout(section: section)
        return layout
    }
    
}

// MARK: - Data Source

private extension ViewController {
    func makeDataSource() -> NSCollectionViewDiffableDataSource<Section, PhotoItem> {

        return NSCollectionViewDiffableDataSource
            <Section, PhotoItem>(collectionView: self.collectionView, itemProvider: {
                (collectionView: NSCollectionView, indexPath: IndexPath, photoItem: PhotoItem) -> NSCollectionViewItem? in
                let item = collectionView.makeItem(withIdentifier: CollectionViewItem.reuseIdentifier, for: indexPath)
                item.textField?.stringValue = photoItem.title
                item.imageView?.image = photoItem.thumbnailImage
            return item
        })
    }
    
}

// MARK: - ThumbnailDelegate

extension ViewController: ThumbnailDelegate {
    
    func thumbnailDidFinish(_ photoItem: PhotoItem) {
        // Finished with generating thumbnail for this photo.
        
        // Find the place to update the thumbnail.
        if let photoIndexPath = dataSource.indexPath(for: photoItem) {
            collectionView.reloadItems(at: Set([IndexPath(item: photoIndexPath.item, section: 0)]))
        }
    }

}
