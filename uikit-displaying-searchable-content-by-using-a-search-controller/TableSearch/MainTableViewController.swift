/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application's main table view controller showing a list of products.
*/

import UIKit

class MainTableViewController: UITableViewController {
    
    let tableViewCellIdentifier = "cellID"
    
    // MARK: - Properties
    
    /// Data model for the table view.
    var products = [Product]()

    /// Search controller to help us with filtering items in the table view.
    var searchController: UISearchController!
    
    /// Search results table view.
    private var resultsTableController: ResultsTableController!
    
    /// Restoration state for UISearchController
    var restoredState = SearchControllerRestorableState()
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let nib = UINib(nibName: "TableCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: tableViewCellIdentifier)
        
        resultsTableController =
            self.storyboard?.instantiateViewController(withIdentifier: "ResultsTableController") as? ResultsTableController
        // This view controller is interested in table view row selections.
        resultsTableController.tableView.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsTableController)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.delegate = self // Monitor when the search button is tapped.
        
        searchController.searchBar.scopeButtonTitles = [Product.productTypeName(forType: .all),
                                                        Product.productTypeName(forType: .birthdays),
                                                        Product.productTypeName(forType: .weddings),
                                                        Product.productTypeName(forType: .funerals)]

        // Place the search bar in the navigation bar.
        navigationItem.searchController = searchController
        
        // Make the search bar always visible.
        navigationItem.hidesSearchBarWhenScrolling = false
        
        /** Search presents a view controller by applying normal view controller presentation semantics.
            This means that the presentation moves up the view controller hierarchy until it finds the root
            view controller or one that defines a presentation context.
        */
        
        /** Specify that this view controller determines how the search controller is presented.
            The search controller should be presented modally and match the physical size of this view controller.
        */
        definesPresentationContext = true
        
        setupDataSource()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Restore the searchController's active state.
        if restoredState.wasActive {
            searchController.isActive = restoredState.wasActive
            restoredState.wasActive = false
            
            if restoredState.wasFirstResponder {
                searchController.searchBar.becomeFirstResponder()
                restoredState.wasFirstResponder = false
            }
        }
    }

}

// MARK: - UITableViewDelegate

extension MainTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedProduct: Product!
        
        // Check to see which table view cell was selected.
        if tableView === self.tableView {
            selectedProduct = product(forIndexPath: indexPath)
        } else {
            selectedProduct = resultsTableController.filteredProducts[indexPath.row]
        }
        
        // Set up the detail view controller to push.
        let detailViewController = DetailViewController.detailViewControllerForProduct(selectedProduct)
        navigationController?.pushViewController(detailViewController, animated: true)

        tableView.deselectRow(at: indexPath, animated: false)
    }
    
}

// MARK: - UITableViewDataSource

extension MainTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // Divide up the table in sections according to the scope of flowers (minus the All scope).
        return searchController.searchBar.scopeButtonTitles!.count - 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String {
        var title = ""
        switch section {
        case 0:
            title = Product.productTypeName(forType: .birthdays)
        case 1:
            title = Product.productTypeName(forType: .weddings)
        case 2:
            title = Product.productTypeName(forType: .funerals)
        default: break
        }
        return title
    }
        
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numInSection = 0
        switch section {
        case 0:
            numInSection = quantity(forType: Product.ProductType.birthdays)
        case 1:
            numInSection = quantity(forType: Product.ProductType.weddings)
        case 2:
            numInSection = quantity(forType: Product.ProductType.funerals)
        default: break
        }
        return numInSection
    }
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: tableViewCellIdentifier, for: indexPath)
        let cellProduct = product(forIndexPath: indexPath)
        
        cell.textLabel?.text = cellProduct.title
        
        let priceString = cellProduct.formattedIntroPrice()
        cell.detailTextLabel?.text = "\(priceString!) | \(cellProduct.yearIntroduced)"
        
		return cell
	}
	
}

// MARK: - UISearchBarDelegate

extension MainTableViewController: UISearchBarDelegate {
	
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
	}
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        updateSearchResults(for: searchController)
    }
	
}

// MARK: - UISearchControllerDelegate

// Use these delegate functions for additional control over the search controller.

extension MainTableViewController: UISearchControllerDelegate {
	
	func presentSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
	}
	
	func willPresentSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
	}
	
	func didPresentSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
	}
	
	func willDismissSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
	}
	
	func didDismissSearchController(_ searchController: UISearchController) {
        //Swift.debugPrint("UISearchControllerDelegate invoked method: \(#function).")
	}
	
}
