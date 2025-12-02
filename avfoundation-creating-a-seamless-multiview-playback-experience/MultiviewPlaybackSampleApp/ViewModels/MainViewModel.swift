/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model for showing the menu view.
*/

import Foundation
import SwiftUI
import AVFoundation
import os

// Define menu navigation routes.
enum MenuNavigationRoute: Hashable {
    case gridViewRoute
    case layoutViewRoute
}

@Observable
class MainViewModel {
    var navigation: [MenuNavigationRoute] = []
    
    var menuItem: MenuItem
    var gridMaxColumns = 0 // Maximum number of columns allowed in a grid based on total number of assets.
    var gridMaxRows = 0  // Maximum number of rows allowed in a grid based on total number of assets.
    
    // MARK: - Life cycle

    init(menu: Menu) {
        // Initialize values from the menu item.
        menuItem = menu.item
        updateValuesFromMenuItem()
    }
    
    // MARK: - Navigation
    
    // Show fixed grid view.
    func showGridView() {
        Logger.general.log("[MainViewModel] Show grid view")
        navigation = [.gridViewRoute]
    }
    
    // Show adjustable layout view.
    func showLayoutView() {
        Logger.general.log("[MainViewModel] Show layout view")
        navigation = [.layoutViewRoute]
    }
    
    // MARK: - Item Selection
    
    // Update states based on menu selection.
    func updateValuesFromMenuItem() {
        // Calculate the maximum number of columns and rows allowed in a grid based on total number of assets.
        let numOfAssets = menuItem.assets.count
        Logger.general.log("[MainViewModel] Menu item has \(numOfAssets) assets")
        
        gridMaxRows = numOfAssets > 0 ? Int(Double(numOfAssets).squareRoot()) : 0
        gridMaxColumns = numOfAssets > 0 ? Int(ceil(Double(numOfAssets) / Double(gridMaxRows))) : 0
    }
    
    // MARK: - Finalize
    
    // Reset any necessary menu states.
    func resetStates() {
        Logger.general.log("[MainViewModel] Reset state")
    }
}

// Extension to help create the main view model from the `Menu.json` file.
extension MainViewModel {

    // Create `MainViewModel`.
    static let createViewModelWithMenu: MainViewModel = {
        do {
            // Get the menu from the `Menu.json`.
            let menu = try Bundle.main.decode(Menu.self, fromJSONFile: "Menu")
            return MainViewModel(menu: menu)
        } catch {
            // Return an empty menu if the app fails to read the `Menu.json` file.
            Logger.general.error("[MainViewModel] Failed to read configuration from `Menu.json`. Error: \(error))")
            let emptyItem = MenuItem(id: UUID(), title: "", description: "", assets: [])
            let emptyMenu = Menu(item: emptyItem)
            return MainViewModel(menu: emptyMenu)
        }
    }()
}
