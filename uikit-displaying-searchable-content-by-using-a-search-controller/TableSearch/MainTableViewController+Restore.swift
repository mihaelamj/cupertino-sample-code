/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application's main table view controller UIStateRestoration support.
*/

import UIKit

extension MainTableViewController {
    
    /// State restoration values.
    enum RestorationKeys: String {
        case viewControllerTitle
        case searchControllerIsActive
        case searchBarText
        case searchBarIsFirstResponder
        case selectedScope
    }
    
    // State items to be restored in viewDidAppear().
    struct SearchControllerRestorableState {
        var wasActive = false
        var wasFirstResponder = false
    }
    
	override func encodeRestorableState(with coder: NSCoder) {
		super.encodeRestorableState(with: coder)
		
		// Encode the view state so it can be restored later.
		
		// Encode the title.
		coder.encode(navigationItem.title!, forKey: RestorationKeys.viewControllerTitle.rawValue)

		// Encode the search controller's active state.
		coder.encode(searchController.isActive, forKey: RestorationKeys.searchControllerIsActive.rawValue)
		
		// Encode the first responser status.
		coder.encode(searchController.searchBar.isFirstResponder, forKey: RestorationKeys.searchBarIsFirstResponder.rawValue)
		
        // Encode the first responser status.
        coder.encode(searchController.searchBar.selectedScopeButtonIndex, forKey: RestorationKeys.selectedScope.rawValue)
        
		// Encode the search bar text.
		coder.encode(searchController.searchBar.text, forKey: RestorationKeys.searchBarText.rawValue)
	}
	
	override func decodeRestorableState(with coder: NSCoder) {
		super.decodeRestorableState(with: coder)
		
		// Restore the title.
		guard let decodedTitle = coder.decodeObject(forKey: RestorationKeys.viewControllerTitle.rawValue) as? String else {
			fatalError("A title did not exist. In your app, handle this gracefully.")
		}
		navigationItem.title! = decodedTitle
		
		/** Restore the active and first responder state:
			We can't make the searchController active here since it's not part of the view hierarchy yet, instead we do it in viewDidAppear.
		*/
		restoredState.wasActive = coder.decodeBool(forKey: RestorationKeys.searchControllerIsActive.rawValue)
		restoredState.wasFirstResponder = coder.decodeBool(forKey: RestorationKeys.searchBarIsFirstResponder.rawValue)
		
        // Restore the scope bar selection.
        searchController.searchBar.selectedScopeButtonIndex = coder.decodeInteger(forKey: RestorationKeys.selectedScope.rawValue)
        
		// Restore the text in the search field.
		searchController.searchBar.text = coder.decodeObject(forKey: RestorationKeys.searchBarText.rawValue) as? String
	}
	
}
