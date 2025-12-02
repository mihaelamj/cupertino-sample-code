/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that displays a list of recipes.
*/

import UIKit

/// - Tag: RecipeListViewController
class RecipeListViewController: UICollectionViewController {
    
    /// - Tag: RecipeListSection
    private enum RecipeListSection: Int {
        case main
    }
    
    /// - Tag: recipeListDataSource
    private var recipeListDataSource: UICollectionViewDiffableDataSource<RecipeListSection, Recipe.ID>!
    
    private var recipeSplitViewController: RecipeSplitViewController {
        self.splitViewController as! RecipeSplitViewController
    }
    
    /// - Tag: RecipeListViewControllerViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clearsSelectionOnViewWillAppear = false

        configureCollectionView()
        configureDataSource()
        loadRecipeData()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(selectedRecipesDidChange(_:)),
            name: .selectedRecipesDidChange,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recipeDidChange(_:)),
            name: .recipeDidChange,
            object: nil
        )
    }
    
    /// - Tag: recipeDidChange
    @objc
    private func recipeDidChange(_ notification: Notification) {
        guard
            // Get `recipeId` from from the `userInfo` dictionary.
            let userInfo = notification.userInfo,
            let recipeId = userInfo[NotificationKeys.recipeId] as? Recipe.ID,
            // Confirm that the data source contains the recipe.
            recipeListDataSource.indexPath(for: recipeId) != nil
        else { return }
        
        // Get the diffable data source's current snapshot.
        var snapshot = recipeListDataSource.snapshot()
        // Update the recipe's data displayed in the collection view.
        snapshot.reconfigureItems([recipeId])
        recipeListDataSource.apply(snapshot, animatingDifferences: true)
    }
    
    /// - Tag: selectedRecipesDidChange
    @objc
    private func selectedRecipesDidChange(_ notification: Notification) {
        // Create a snapshot of the selected recipe identifiers from the notification's
        // `userInfo` dictionary, and apply it to the diffable data source.
        guard
            let userInfo = notification.userInfo,
            let selectedRecipeIds = userInfo[NotificationKeys.selectedRecipeIds] as? [Recipe.ID]
        else { return }
        
        var snapshot = NSDiffableDataSourceSnapshot<RecipeListSection, Recipe.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(selectedRecipeIds, toSection: .main)
        recipeListDataSource.apply(snapshot, animatingDifferences: true)

        // The design of this sample app makes it possible for the selected
        // recipe displayed in the secondary (detail) view controller to exist
        // in the new snapshot but not exist in the collection view prior to
        // applying the snapshot. For instance, while displaying the list of
        // favorite recipes, a person can unfavorite the selected recipe by tapping
        // the `isFavorite` button. This removes the selected recipe from the
        // favorites list. Tap the button again and the recipe reappears in the
        // list. In this scenario, the app needs to re-select the recipe so it
        // appears as selected in the collection view.
        selectRecipeIfNeeded()
    }
    
    // The sidebar calls showRecipes() each time a person selects a sidebar item.
    func showRecipes() {
        loadRecipeData()
        selectRecipeIfNeeded()
    }
    
    /// - Tag: loadRecipeData
    private func loadRecipeData() {
        // Retrieve the list of recipe identifiers determined based on a
        // selected sidebar item such as All Recipes or Favorites.
        guard let recipeIds = recipeSplitViewController.selectedRecipes?.recipeIds()
        else { return }
        
        // Update the collection view by adding the recipe identifiers to
        // a new snapshot, and apply the snapshop to the diffable data source.
        var snapshot = NSDiffableDataSourceSnapshot<RecipeListSection, Recipe.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(recipeIds, toSection: .main)
        recipeListDataSource.applySnapshotUsingReloadData(snapshot)
    }
        
    private func selectRecipeIfNeeded() {
        guard let selectedRecipeId = recipeSplitViewController.selectedRecipeId else { return }
        let indexPath = recipeListDataSource.indexPath(for: selectedRecipeId)
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .bottom)
    }
    
}

extension RecipeListViewController {
    
    @IBAction func addRecipe(_ sender: Any) {
        // The focus on this sample is diffable data source. So instead of providing a
        // recipe editor, the sample creates a hard-coded recipe and adds it to the data store.
        var recipe = dataStore.newRecipe()
        recipe.title = "Diffable Dumplings"
        recipe.prepTime = 60
        recipe.cookTime = 900
        recipe.servings = "1"
        recipe.ingredients = "A dash of Swift\nA spinkle of data"
        recipe.directions = "Mix the ingredients in a data source. Then add to collection view."
        
        var collections = ["New Recipes"] // Always add new recipes to this collection.
        if let selectedRecipes = recipeSplitViewController.selectedRecipes {
            recipe.isFavorite = selectedRecipes.type == .favorites
            if selectedRecipes.type == .collections {
                if let collectionName = selectedRecipes.collectionName {
                    collections.append(collectionName)
                }
            }
        }
        recipe.collections = collections
        
        let addedRecipe = dataStore.add(recipe)
        
        // Select the new recipe in the collection view.
        recipeSplitViewController.selectedRecipeId = addedRecipe.id
        selectRecipeIfNeeded()
    }
    
    private func delete(_ recipe: Recipe) -> Bool {
        let didDelete = dataStore.delete(recipe)
        if didDelete {
            if let selectedRecipeId = recipeSplitViewController.selectedRecipeId,
               recipe.id == selectedRecipeId {
                recipeSplitViewController.selectedRecipeId = nil
            }
        }
        return didDelete
    }
    
    private func toggleIsFavorite(_ recipe: Recipe) -> Bool {
        var recipeToUpdate = recipe
        recipeToUpdate.isFavorite.toggle()
        return dataStore.update(recipeToUpdate) != nil
    }
    
}

extension RecipeListViewController {
    
    private func configureCollectionView() {
        let layout = UICollectionViewCompositionalLayout { sectionIndex, layoutEnvironment in
            var configuration = UICollectionLayoutListConfiguration(appearance: .sidebarPlain)
            configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
                return self?.trailingSwipeActionsConfiguration(for: indexPath)
            }
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: layoutEnvironment)
            return section
        }
        
        collectionView.collectionViewLayout = layout
    }
    
    private func trailingSwipeActionsConfiguration(for indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let recipeId = recipeListDataSource.itemIdentifier(for: indexPath),
              let recipe = dataStore.recipe(with: recipeId)
        else { return nil }
        
        let configuration = UISwipeActionsConfiguration(actions: [
            deleteContextualAction(recipe: recipe),
            favoriteContextualAction(recipe: recipe)
        ])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
    
    private func deleteContextualAction(recipe: Recipe) -> UIContextualAction {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            completionHandler(self.delete(recipe))
        }
        deleteAction.image = UIImage(systemName: "trash")
        return deleteAction
    }

    private func favoriteContextualAction(recipe: Recipe) -> UIContextualAction {
        let title = recipe.isFavorite ? "Remove from Favorites" : "Add to Favorites"
        let action = UIContextualAction(style: .normal, title: title) { [weak self] _, _, completionHandler in
            guard let self = self else { return }
            completionHandler(self.toggleIsFavorite(recipe))
        }
        let name = recipe.isFavorite ? "heart" : "heart.fill"
        action.image = UIImage(systemName: name)
        return action
    }

}

extension RecipeListViewController {
    
    /// - Tag: configureDataSource
    private func configureDataSource() {
        // Create a cell registration that the diffable data source will use.
        let recipeCellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Recipe> { cell, indexPath, recipe in
            var contentConfiguration = UIListContentConfiguration.subtitleCell()
            contentConfiguration.text = recipe.title
            contentConfiguration.secondaryText = recipe.subtitle
            contentConfiguration.image = recipe.smallImage
            contentConfiguration.imageProperties.cornerRadius = 4
            contentConfiguration.imageProperties.maximumSize = CGSize(width: 60, height: 60)
            
            cell.contentConfiguration = contentConfiguration
            
            if recipe.isFavorite {
                let image = UIImage(systemName: "heart.fill")
                let accessoryConfiguration = UICellAccessory.CustomViewConfiguration(customView: UIImageView(image: image),
                                                                                     placement: .trailing(displayed: .always),
                                                                                     tintColor: .secondaryLabel)
                cell.accessories = [.customView(configuration: accessoryConfiguration)]
            } else {
                cell.accessories = []
            }
        }

        // Create the diffable data source and its cell provider.
        recipeListDataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) {
            collectionView, indexPath, identifier -> UICollectionViewCell in
            // `identifier` is an instance of `Recipe.ID`. Use it to
            // retrieve the recipe from the backing data store.
            let recipe = dataStore.recipe(with: identifier)!
            return collectionView.dequeueConfiguredReusableCell(using: recipeCellRegistration, for: indexPath, item: recipe)
        }
    }
    
}

extension RecipeListViewController {
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let recipeId = recipeListDataSource.itemIdentifier(for: indexPath) {
            recipeSplitViewController.selectedRecipeId = recipeId
        }
    }
    
}
