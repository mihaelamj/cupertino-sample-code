/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A grid of recipe tiles, based on a given recipe category.
*/

import SwiftUI

struct RecipeGrid: View {
    var dataModel = DataModel.shared

    /// The category of recipes to display.
    let category: Category?

    /// The recipes of the category.
    private var recipes: [Recipe] {
        dataModel.recipes(in: category)
    }

    /// A `Binding` to the identifier of the selected recipe.
    @Binding var selection: Recipe.ID?
    
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(NavigationModel.self) private var navigationModel

    /// The currently-selected recipe.
    private var selectedRecipe: Recipe? {
        dataModel[selection]
    }

    private func gridItem(for recipe: Recipe) -> some View {
        RecipeTile(recipe: recipe, isSelected: selection == recipe.id)
            .id(recipe.id)
            .padding(Self.spacing)
            #if os(macOS)
            .onTapGesture {
                selection = recipe.id
            }
            .simultaneousGesture(TapGesture(count: 2).onEnded {
                navigationModel.selectedRecipeID = recipe.id
            })
            #else
            .onTapGesture {
                navigationModel.selectedRecipeID = recipe.id
            }
            #endif
    }

    var body: some View {
        if let category = category {
            container { geometryProxy, scrollViewProxy in
                LazyVGrid(columns: columns) {
                    ForEach(recipes) { recipe in
                        gridItem(for: recipe)
                    }
                }
                .padding(Self.spacing)
                .focusable()
                .focusEffectDisabled()
                .focusedValue(\.selectedRecipe, selectedRecipe)
                #if os(macOS)
                .onMoveCommand { direction in
                    return selectRecipe(
                        in: direction,
                        layoutDirection: layoutDirection,
                        geometryProxy: geometryProxy,
                        scrollViewProxy: scrollViewProxy)
                }
                #endif
                .onKeyPress(.return, action: {
                    if let recipe = selectedRecipe {
                        navigate(to: recipe)
                        return .handled
                    } else {
                        return .ignored
                    }
                })
                .onKeyPress(.escape) {
                    selection = nil
                    return .handled
                }
                .onKeyPress(characters: .alphanumerics, phases: .down) { keyPress in
                    selectRecipe(
                        matching: keyPress.characters,
                        scrollViewProxy: scrollViewProxy)
                }
            }
            .navigationTitle(category.localizedName)
            .navigationDestination(for: Recipe.ID.self) { recipeID in
                if let recipe = dataModel[recipeID] {
                    RecipeDetail(recipe: recipe) { relatedRecipe in
                        RelatedRecipeLink(recipe: relatedRecipe)
                    }
                }
            }
        } else {
            ContentUnavailableView("Choose a category", systemImage: "fork.knife")
                .navigationTitle("")
        }
    }

    private func container<Content: View>(
        @ViewBuilder content: @escaping (
            _ geometryProxy: GeometryProxy, _ scrollViewProxy: ScrollViewProxy) -> Content
    ) -> some View {
        GeometryReader { geometryProxy in
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    content(geometryProxy, scrollViewProxy)
                }
            }
        }
    }

    // MARK: Keyboard selection

    private func navigate(to recipe: Recipe) {
        navigationModel.selectedRecipeID = recipe.id
    }

    #if os(macOS)
    private func selectRecipe(
        in direction: MoveCommandDirection,
        layoutDirection: LayoutDirection,
        geometryProxy: GeometryProxy,
        scrollViewProxy: ScrollViewProxy
    ) {
        let direction = direction.transform(from: layoutDirection)
        let rowWidth = geometryProxy.size.width - RecipeGrid.spacing * 2
        let recipesPerRow = Int(floor(rowWidth / RecipeTile.size))

        var newIndex: Int
        if let currentIndex = recipes.firstIndex(where: { $0.id == selection }) {
            switch direction {
            case .left:
                if currentIndex % recipesPerRow == 0 { return }
                newIndex = currentIndex - 1
            case .right:
                if currentIndex % recipesPerRow == recipesPerRow - 1 { return }
                newIndex = currentIndex + 1
            case .up:
                newIndex = currentIndex - recipesPerRow
            case .down:
                newIndex = currentIndex + recipesPerRow
            @unknown default:
                return
            }
        } else {
            newIndex = 0
        }

        if newIndex >= 0 && newIndex < recipes.count {
            selection = recipes[newIndex].id
            scrollViewProxy.scrollTo(selection)
        }
    }
    #endif

    private func selectRecipe(
        matching characters: String,
        scrollViewProxy: ScrollViewProxy
    ) -> KeyPress.Result {
        if let matchedRecipe = recipes.first(where: { recipe in
            recipe.name.lowercased().starts(with: characters)
        }) {
            selection = matchedRecipe.id
            scrollViewProxy.scrollTo(selection)
            return .handled
        }
        return .ignored
    }

    // MARK: Grid layout

    private static let spacing: CGFloat = 10

    private var columns: [GridItem] {
        [ GridItem(.adaptive(minimum: RecipeTile.size), spacing: 0) ]
    }
}

#if os(macOS)
extension MoveCommandDirection {
    /// Flip direction for right-to-left language environments.
    /// Learn more: https://developer.apple.com/design/human-interface-guidelines/right-to-left
    func transform(from layoutDirection: LayoutDirection) -> MoveCommandDirection {
        if layoutDirection == .rightToLeft {
            switch self {
            case .left:     return .right
            case .right:    return .left
            default:        break
            }
        }
        return self
    }
}
#endif
