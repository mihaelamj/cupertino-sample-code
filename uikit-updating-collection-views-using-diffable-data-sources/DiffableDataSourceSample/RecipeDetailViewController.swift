/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that displays the details of the selected recipe.
*/

import UIKit

class RecipeDetailViewController: UIViewController {

    @IBOutlet var recipeTitle: UILabel!
    @IBOutlet var recipeSubtitle: UILabel!
    @IBOutlet var recipeImageView: UIImageView!
    @IBOutlet var recipeIngredients: UITextView!
    @IBOutlet var recipeDirections: UITextView!
    @IBOutlet var favoriteButton: UIBarButtonItem!
    @IBOutlet var deleteButton: UIBarButtonItem!
    @IBOutlet var contentStackView: UIStackView!

    private var recipeId: Recipe.ID?

    func showDetail(with recipe: Recipe) {
        recipeId = recipe.id
        recipeTitle.text = recipe.title
        recipeSubtitle.text = recipe.subtitle
        recipeImageView.image = recipe.fullImage
        recipeIngredients.attributedText = makeAttributedString(text: recipe.ingredients, paragraphStyle: ingredientsParagraphStyle)
        recipeDirections.attributedText = makeAttributedString(text: recipe.directions, paragraphStyle: directionsParagraphStyle)

        favoriteButton.image = recipe.isFavorite ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart")
        
        contentStackView.alpha = 1.0
        favoriteButton.isEnabled = true
        deleteButton.isEnabled = true
    }
    
    func hideDetail(animated: Bool = true) {
        recipeId = nil
        if animated {
            UIViewPropertyAnimator.runningPropertyAnimator(
                withDuration: 0.2,
                delay: 0.0,
                options: .curveEaseIn,
                animations: {
                    self.contentStackView.alpha = 0.0
                    self.favoriteButton.isEnabled = false
                    self.deleteButton.isEnabled = false
                },
                completion: nil
            )
        } else {
            contentStackView.alpha = 0.0
            self.favoriteButton.isEnabled = false
            self.deleteButton.isEnabled = false
        }
    }

    private lazy var ingredientsParagraphStyle: NSParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = 1.75
        return paragraphStyle
    }()
    
    private lazy var directionsParagraphStyle: NSParagraphStyle = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacingBefore = 12
        return paragraphStyle
    }()

    private func makeAttributedString(text: String, paragraphStyle: NSParagraphStyle) -> NSAttributedString {
        let attributes = [
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body),
            NSAttributedString.Key.foregroundColor: UIColor.label
        ]
        return  NSMutableAttributedString(string: text, attributes: attributes)
    }

    private var recipeSplitViewController: RecipeSplitViewController {
        self.splitViewController as! RecipeSplitViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        hideDetail(animated: false)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recipeDidChange(_:)),
            name: .recipeDidChange,
            object: nil
        )

    }
    
    @objc
    private func recipeDidChange(_ notification: Notification) {
        // The notification contains the recipe that changed. If
        // that recipe is the same as the one shown in this view
        // controller, then update the UI with the latest recipe
        // data.
        guard
            let userInfo = notification.userInfo,
            let recipe = userInfo[NotificationKeys.recipe] as? Recipe
        else { return }
        
        if recipe.id == self.recipeId {
            showDetail(with: recipe)
        }
    }

}

extension RecipeDetailViewController {

    @IBAction func deleteRecipe(_ sender: Any) {
        guard
            let id = recipeSplitViewController.selectedRecipeId,
            let recipe = dataStore.recipe(with: id)
        else { return }

        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            if dataStore.delete(recipe) {
                self?.recipeSplitViewController.selectedRecipeId = nil
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        
        #if targetEnvironment(macCatalyst)
        let preferredStyle = UIAlertController.Style.alert
        #else
        let preferredStyle = UIAlertController.Style.actionSheet
        #endif
        
        let alert = UIAlertController(
            title: "Are you sure you want to delete \(recipe.title)?",
            message: nil,
            preferredStyle: preferredStyle)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        if let popoverPresentationController = alert.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender as? UIBarButtonItem
        }
        
        present(alert, animated: true, completion: nil)
    }

    @IBAction func toggleIsFavorite(_ sender: Any) {
        guard
            let id = recipeSplitViewController.selectedRecipeId,
            var recipeToUpdate = dataStore.recipe(with: id)
        else { return }
        
        recipeToUpdate.isFavorite.toggle()
        dataStore.update(recipeToUpdate)
        
        // Update the display.
        showDetail(with: recipeToUpdate)
    }
    
}
