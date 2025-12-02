/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that displays a three-column split view.
*/

import UIKit

struct SelectedRecipes {
    
    enum SelectedRecipeType {
        case all, favorites, recents, collections
    }
    
    let type: SelectedRecipeType
    let collectionName: String?
    
    init(type: SelectedRecipeType, collectionName: String? = nil) {
        self.type = type
        self.collectionName = collectionName
    }
    
    func recipes() -> [Recipe] {
        switch type {
        case .all:
            return dataStore.allRecipes
        case .favorites:
            return dataStore.favoriteRecipes()
        case .recents:
            return dataStore.recentRecipes()
        case .collections:
            return dataStore.recipesInCollection(collectionName)
        }
    }
    
    func recipeIds() -> [Recipe.ID] {
        return recipes().map { $0.id }
    }
    
}

class RecipeSplitViewController: UISplitViewController {

    var selectedRecipes: SelectedRecipes? {
        didSet {
            guard
                let navController = self.viewController(for: .supplementary) as? UINavigationController,
                let recipeListViewController = navController.topViewController as? RecipeListViewController
            else { return }
            
            recipeListViewController.showRecipes()
        }
    }
    
    var selectedRecipeId: Recipe.ID? {
        didSet {
            if let id = selectedRecipeId {
                showRecipeDetail(with: id)
            } else {
                hideRecipeDetail()
                show(.supplementary)
            }
        }
    }
    
    var recipeCollections: [String] {
        dataStore.collections
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(
            self,
            selector: #selector(recipeDidAddChangeDelete(_:)),
            name: .recipeDidAdd,
            object: dataStore)
        notificationCenter.addObserver(
            self,
            selector: #selector(recipeDidAddChangeDelete(_:)),
            name: .recipeDidChange,
            object: dataStore)
        notificationCenter.addObserver(
            self,
            selector: #selector(recipeDidAddChangeDelete(_:)),
            name: .recipeDidDelete,
            object: dataStore)
    }
    
    @objc
    private func recipeDidAddChangeDelete(_ notification: Notification) {
        // Let the sidebar and primary view controllers know that the list
        // of selected recipes changed as a result of adding, deleting, or
        // changing a recipe.
        
        if let selectedRecipes = self.selectedRecipes {
            // Include the selected recipe identifiers in the notification.
            NotificationCenter.default.post(
                name: .selectedRecipesDidChange,
                object: self,
                userInfo: [NotificationKeys.selectedRecipeIds: selectedRecipes.recipeIds()])
        }
    }
}

extension RecipeSplitViewController {

    private func showRecipeDetail(with recipeId: Recipe.ID) {
        guard
            let navController = self.viewController(for: .secondary) as? UINavigationController,
            let recipeDetailViewController = navController.topViewController as? RecipeDetailViewController,
            let recipe = dataStore.recipe(with: recipeId)
        else { return }

        recipeDetailViewController.showDetail(with: recipe)
    }
    
    private func hideRecipeDetail() {
        guard
            let navController = self.viewController(for: .secondary) as? UINavigationController,
            let recipeDetailViewController = navController.topViewController as? RecipeDetailViewController
        else { return }

        recipeDetailViewController.hideDetail()
    }

}
