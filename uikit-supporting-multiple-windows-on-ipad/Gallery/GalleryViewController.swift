/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view controller that displays a collection of photos, and shows how to create a new scene session via drag and drop.
*/

import UIKit

class GalleryViewController: UIViewController {

    // The photo data displayed in the collection view.
    let photos = PhotoManager.shared.photos
    
    enum Section {
        case main
    }

    #if targetEnvironment(macCatalyst)
    // As a Mac Catalyst app, an 'NSToolbar' is used to inspect a photo.
    var infoToolbarItem: NSToolbarItem!
    #endif
    
    var dataSource: UICollectionViewDiffableDataSource<Section, Int>! = nil
    var collectionView: UICollectionView! = nil
    
    // MARK: - View controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.delegate = self
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: PhotoCell.reuseIdentifier)
        collectionView.dragDelegate = self // Allow photos to be dragged out (so that 'itemsForBeginning' is called).
        collectionView.allowsSelection = true
        view.addSubview(collectionView)
 
        configureDataSource()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
        #if targetEnvironment(macCatalyst)
        // As a Mac Catalyst app, don't display the navigation bar, and instead use 'NSToolbar'.
        navigationController?.setNavigationBarHidden(true, animated: animated)

        if view.window!.windowScene?.titlebar?.toolbar == nil {
            let toolbar = NSToolbar(identifier: GalleryViewController.toolbarID)
            toolbar.allowsUserCustomization = false
            toolbar.displayMode = .iconOnly
            toolbar.delegate = self
            view.window!.windowScene?.titlebar?.toolbar = toolbar
            view.window!.windowScene?.titlebar?.titleVisibility = .visible
        }
        #endif
    }
    
    // MARK: - Actions
    
    override func validate(_ command: UICommand) {
        if command.action == #selector(inspect(_:)) {
            if let indexPaths = collectionView.indexPathsForSelectedItems {
                if indexPaths.isEmpty {
                    command.attributes = .disabled
                }
            }
        }
        super.validate(command)
    }
    
    @objc
    func inspect(_ sender: Any?) {
        if let indexPaths = collectionView.indexPathsForSelectedItems {
            createNewScene(indexPath: indexPaths[0])
        }
    }
    
    func navigateToPhoto(indexPath: IndexPath) {
        let selectedPhoto = photos[indexPath.row]
        if let detailViewController = PhotoDetailViewController.loadFromStoryboard() {
            detailViewController.photo = selectedPhoto
            navigationController?.pushViewController(detailViewController, animated: true)
        }
    }
    
    // MARK: - UICollectionView
    
    func createLayout() -> UICollectionViewLayout {
        let itemSize =
            NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.2),
                                   heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets =
            NSDirectionalEdgeInsets(top: 5.0, leading: 5.0, bottom: 5.0, trailing: 5.0)

        let groupSize =
            NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                   heightDimension: .fractionalWidth(0.2))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }
    
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Int>(collectionView: collectionView) { [self]
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: Int) -> UICollectionViewCell? in

            // Get a cell of the desired kind.
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: PhotoCell.reuseIdentifier,
                for: indexPath) as? PhotoCell
                else { fatalError("Cannot create new cell") }

            // Populate the cell with the item description.
            let photo = photos[indexPath.row]
            cell.photoView.image = UIImage(named: photo.assetName)

            return cell
        }

        // Initial data.
        var snapshot = NSDiffableDataSourceSnapshot<Section, Int>()
        snapshot.appendSections([.main])
        snapshot.appendItems(Array(0..<7))
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func createNewScene(indexPath: IndexPath) {
        let photo = photos[indexPath.row]
        
        let requestingScene = self.view.window!.windowScene

        InspectorSceneDelegate.openInspectorSceneSessionForPhoto(photo, requestingScene: requestingScene!, errorHandler: { error in
            // Hande the error.
        })
    }
}

// MARK: - UICollectionViewDragDelegate

extension GalleryViewController: UICollectionViewDragDelegate {
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        var dragItems = [UIDragItem]()
        let selectedPhoto = photos[indexPath.row]
        if let imageToDrag = UIImage(named: selectedPhoto.assetName) {
            let userActivity = selectedPhoto.detailUserActivity
            let itemProvider = NSItemProvider(object: imageToDrag)
            itemProvider.registerObject(userActivity, visibility: .all)

            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = selectedPhoto
            dragItems.append(dragItem)
        }
        return dragItems
    }
    
}

// MARK: - UICollectionViewDelegate

extension GalleryViewController: UICollectionViewDelegate {
    // Handle photo selection in the collection view:
    //
    #if targetEnvironment(macCatalyst)
    // Just select the photo in Mac Catalyst.
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        infoToolbarItem.isEnabled = true
    }
    #else
    // Navigate to this photo by pushing the 'PhotoDetalViewController' in iOS.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Navigate to a photo only on iOS.
        navigateToPhoto(indexPath: indexPath)
    }
    #endif
    
    // MARK: - Actions
    
    func inspectAction(_ indexPath: IndexPath) -> UIAction {
        return UIAction(title: "Inspect",
                        image: UIImage(systemName: "info.circle")) { [self] action in
            if UIApplication.shared.supportsMultipleScenes {
                createNewScene(indexPath: indexPath)
            } else {
                self.navigateToPhoto(indexPath: indexPath)
            }
        }
    }
    
    func shareAction(_ indexPath: IndexPath) -> UIAction {
        return UIAction(title: "Share",
                        image: UIImage(systemName: "square.and.arrow.up")) { [self] action in
            let photo = photos[indexPath.row]
            guard let photoToShare = UIImage(named: photo.assetName) else { return }
            let activityItems = [photoToShare] as [Any]
            
            // Present 'UIActivityViewController' anchored from the collection view cell.
            let activityViewController =
                UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            
            guard let cell = collectionView.cellForItem(at: indexPath) else { return }
            activityViewController.popoverPresentationController?.sourceView = cell
            activityViewController.popoverPresentationController?.sourceRect = cell.bounds
            
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Context Menu
    
    func collectionView(_ collectionView: UICollectionView,
                        willEndContextMenuInteraction configuration: UIContextMenuConfiguration,
                        animator: UIContextMenuInteractionAnimating?) {
        // The cell's context menu is closing.
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        contextMenuConfigurationForItemAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            // Build the context menu with a series of UIActions.
            var contextMenuActions = [UIAction]()

            // Add the Inspect action.
            let newSceneAction = self.inspectAction(indexPath)
            contextMenuActions.append(newSceneAction)
        
            // Add the Share action.
            let shareAction = self.shareAction(indexPath)
            contextMenuActions.append(shareAction)
            
            return UIMenu(title: "", children: contextMenuActions)
        }
    }
    
    // MARK: - Context Menu Preview
    
    // Called when the interaction begins. Return a 'UITargetedPreview' describing the desired highlight preview.
    func collectionView(_ collectionView: UICollectionView,
                        previewForHighlightingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return makeTargetedPreview(for: configuration)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        previewForDismissingContextMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        return makeTargetedPreview(for: configuration)
    }
    
    private func makeTargetedPreview(for configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        // Ensure you can get the expected identifier.
        if let configIdentifier = configuration.identifier as? String {
            guard let row = Int(configIdentifier) else { return nil }
            
            // Get the cell for the index of the model.
            guard let cell = collectionView.cellForItem(at: .init(row: row, section: 0)) else { return nil }
            
            let parameters = UIPreviewParameters()
            let visibleRect = cell.contentView.bounds.insetBy(dx: -10, dy: -10)
            let visiblePath = UIBezierPath(roundedRect: visibleRect, cornerRadius: 20.0)
            parameters.visiblePath = visiblePath
            parameters.backgroundColor = UIColor.systemTeal
            
            return UITargetedPreview(view: cell.contentView, parameters: parameters)
        } else {
            return nil
        }
    }
    
}
