/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view controller.
*/

import UIKit

final class ViewController: UIViewController {
    // MARK: Properties

    @IBOutlet var collectionView: UICollectionView!

    private let dataSource = CustomDataSource()

    // MARK: UIViewController overrides

    /// - Tag: SetDataSources
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the collection view's data source.
        collectionView.dataSource = dataSource
      
        // Set the collection view's prefetching data source.
        collectionView.prefetchDataSource = dataSource
      
        // Add a border to the collection view's layer so its edges are visible.
        collectionView.layer.borderColor = UIColor.black.cgColor
    }
}
