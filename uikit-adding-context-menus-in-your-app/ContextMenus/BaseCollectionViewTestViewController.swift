/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Super class table view controller for managing collection-based test cases.
*/

import UIKit

class BaseCollectionViewTestViewController: UICollectionViewController {
    
    private let sectionInsets = UIEdgeInsets(top: 6.0, left: 6.0, bottom: 6.0, right: 6.0)
    
    enum Section { case main }
    var dataSource: UICollectionViewDiffableDataSource<Section, Model>! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let flowLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.minimumLineSpacing = sectionInsets.left
            flowLayout.minimumInteritemSpacing = sectionInsets.left
            flowLayout.sectionInset = sectionInsets
            flowLayout.itemSize = itemSize()
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, Model>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, model: Model) -> UICollectionViewCell? in

            // Get a cell of the desired kind.
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CollectionViewCell.reuseIdentifier,
                for: indexPath) as? CollectionViewCell else { fatalError("Cannot create new cell") }
            
            cell.imageView.image = UIImage(named: model.name)
            return cell
        }
        
        // Set the Initial data.
        var snapshot = NSDiffableDataSourceSnapshot<Section, Model>()
        snapshot.appendSections([.main])
        let models = (0..<8).map { Model.createItem(index: $0) }
        snapshot.appendItems(models)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    func itemSize() -> CGSize {
        let itemsPerRow: CGFloat = view.traitCollection.horizontalSizeClass == .regular ? 10 : 4
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
}
