/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Demonstrates the system search button in the toolbar.
*/

import UIKit

class ToolbarSystemSearchViewController: UIViewController {
    
    var searchController: UISearchController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Builds the navigation bar.
        let selectBarButton = UIBarButtonItem(title: NSLocalizedString("Select", comment: ""),
                                              style: .plain,
                                              target: nil,
                                              action: nil)
        let shareBarButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"),
                                             style: .plain,
                                             target: nil,
                                             action: nil)
        let infoBarButton = UIBarButtonItem(image: UIImage(systemName: "info.circle"),
                                            style: .plain,
                                            target: nil,
                                            action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done,
                                            target: nil,
                                            action: nil)

        navigationItem.rightBarButtonItems = [doneBarButton,
                                              shareBarButton,
                                              infoBarButton,
                                              selectBarButton]

        // Configures the navigation item with the search controller
        searchController = UISearchController(searchResultsController: SearchResultsViewController())
        navigationItem.searchController = searchController

        // Builds the toolbar.
        toolbarItems = [
            .init(image: UIImage(systemName: "location")),
            .init(image: UIImage(systemName: "number")),
            .init(image: UIImage(systemName: "camera")),
            UIBarButtonItem.flexibleSpace(),
            navigationItem.searchBarPlacementBarButtonItem
        ]
    }
}

class SearchResultsViewController: UIViewController {
    
}
