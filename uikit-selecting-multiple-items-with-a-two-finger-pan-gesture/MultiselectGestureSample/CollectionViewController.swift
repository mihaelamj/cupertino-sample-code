/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller showing that supports a two-finger pan gesture for selecting multiple items.
*/

import UIKit

class CollectionViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    private let photos = PhotoModel.generatePhotosItems(count: 100)
    private let sectionInsets = UIEdgeInsets(top: 1.0, left: 1.0, bottom: 1.0, right: 1.0)
    private var isPad = false

    override func viewDidLoad() {
        super.viewDidLoad()
        isPad = view.traitCollection.userInterfaceIdiom == .pad
        collectionView.allowsSelection = true
        collectionView.allowsMultipleSelection = false
        collectionView.allowsMultipleSelectionDuringEditing = true
        collectionView.allowsFocus = true
        collectionView.allowsFocusDuringEditing = true
        collectionView.selectionFollowsFocus = true
        
        setEditing(false, animated: false)
        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.minimumLineSpacing = sectionInsets.left
            flowLayout.minimumInteritemSpacing = sectionInsets.left
            flowLayout.sectionInset = sectionInsets
            flowLayout.itemSize = itemSize()
        }
        updateUserInterface()
    }

    func updateUserInterface() {
        guard let button = navigationItem.rightBarButtonItem else { return }
        button.title = isEditing ? "Done" : "Select"
    }
    
    func itemSize() -> CGSize {
        let itemsPerRow: CGFloat = isPad ? 10 : 3
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        if isEditing != editing {
            super.setEditing(editing, animated: animated)
            collectionView.isEditing = editing
            
            // Reload visible items to make sure our collection view cells show their selection indicators.
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
            if !editing {
                // Clear selection if leaving edit mode.
                collectionView.indexPathsForSelectedItems?.forEach({ (indexPath) in
                    collectionView.deselectItem(at: indexPath, animated: animated)
                })
            }
            
            updateUserInterface()
        }
    }

    @IBAction func toggleSelectionMode(_ sender: Any) {
        // Toggle selection state.
        setEditing(!isEditing, animated: true)
    }
    
}

extension CollectionViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CollectionViewCell.reuseIdentifier, for: indexPath)

        if let photoCell = cell as? CollectionViewCell {
            photoCell.configureCell(with: photos[indexPath.item], showSelectionIcons: isEditing)
        }
    
        return cell
    }
    
}

extension CollectionViewController: UICollectionViewDelegate {

    // MARK: - Multiple selection methods.

    /// - Tag: collection-view-multi-select
    func collectionView(_ collectionView: UICollectionView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        // Returning `true` automatically sets `collectionView.isEditing`
        // to `true`. The app sets it to `false` after the user taps the Done button.
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didBeginMultipleSelectionInteractionAt indexPath: IndexPath) {
        // Replace the Select button with Done, and put the
        // collection view into editing mode.
        setEditing(true, animated: true)
    }
    
    func collectionViewDidEndMultipleSelectionInteraction(_ collectionView: UICollectionView) {
        print("\(#function)")
    }
    
}
