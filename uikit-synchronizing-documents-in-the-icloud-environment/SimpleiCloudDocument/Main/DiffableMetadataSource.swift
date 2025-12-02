/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The diffable data source class that provides metadata items for a table view.
*/

import UIKit

// MetadataItem is a wrapper of NSMetadataItem.
// When users rename an item, nsMetadataItem is the same, but the URL is different.
// Use url.path to implement Hashable and Equatable because only url.path is visible.
//
struct MetadataItem: Hashable {
    let nsMetadataItem: NSMetadataItem?
    let url: URL
    
    static func == (lhs: MetadataItem, rhs: MetadataItem) -> Bool {
        return lhs.url.path == rhs.url.path
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url.path)
    }
}

class DiffableMetadataSource: UITableViewDiffableDataSource<Int, MetadataItem> {
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

typealias DiffableMetadataSourceSnapshot = NSDiffableDataSourceSnapshot<Int, MetadataItem>
