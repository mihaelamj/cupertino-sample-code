/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The diffable data source class that provides image items for a collection view.
*/

import UIKit

typealias DiffableImageSource = UICollectionViewDiffableDataSource<Int, ImageItem>
typealias DiffableImageSourceSnapshot = NSDiffableDataSourceSnapshot<Int, ImageItem>

struct ImageItem: Hashable {
    let name: String
    let thumbnail: UIImage?
    
    // Only key matters for Hashable and Equatable.
    //
    static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
        return lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}
