/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation for the category selection view.
*/

import SwiftUI

/// A view that allows activity participants to select which categories
/// they'd like to play with.
///
/// For example, they may want to play with phrases from historical
/// events, or with something simpler, such as different fruits and vegetables.
///
///```
/// ┌────────────────────────────────────┐
/// │                                    │
/// │ Film & Television               □  │
/// │ Fruits & Vegetables             ■  │
/// │ Historical Events               □  │
/// │ ...                             □  │
/// │                                    │
/// │                                    │
/// │             ┌────────┐             │
/// │             │ Play ▶ │             │
/// │             └────────┘             │
/// └────────────────────────────────────┘
/// ```
struct CategorySelectionView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        // Present the gameplay category options.
        Form {
            Section {
                ForEach(PhraseManager.shared.categories, id: \.self) { category in
                    Toggle(category.description, isOn: isCategoryActive(category))
                }
            } header: {
                Text("Categories")
            } footer: {
                Text("Select the categories you'd like to play with.")
            }
        }
        .guessTogetherToolbar()
        
        Button("Play", systemImage: "play") {
            appModel.sessionController?.enterTeamSelection()
        }
        .padding(.vertical)
    }
    
    /// Creates a binding Boolean for each category that it connects to that category's selection UI.
    ///
    /// - Parameters:
    ///     - category: The gameplay category.
    func isCategoryActive(_ category: String) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                if let sessionController = appModel.sessionController {
                    return !sessionController.game.excludedCategories.contains(category)
                } else {
                    return false
                }
            },
            set: { isOn in
                if isOn {
                    appModel.sessionController?.game.excludedCategories.remove(category)
                } else {
                    let excludedCategoriesCount = appModel.sessionController?.game.excludedCategories.count ?? 0
                    guard excludedCategoriesCount + 1 < PhraseManager.shared.categories.count else {
                        return
                    }
                    
                    appModel.sessionController?.game.excludedCategories.insert(category)
                }
            }
        )
    }
}
