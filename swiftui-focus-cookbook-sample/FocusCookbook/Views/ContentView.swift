/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view the app uses to present the navigation experience
  picker and change the app navigation architecture based on the user selection.
*/

import SwiftUI

struct ContentView: View {
    @State private var showGroceryList: Bool = false
    @SceneStorage("model") private var model: Data?
    @State private var navigationModel = NavigationModel(groceryList: .sample)

    var body: some View {
        RecipeNavigationView(navigationModel: navigationModel, showGroceryList: $showGroceryList)
            .environment(navigationModel)
            .sheet(isPresented: $showGroceryList) {
                GroceryListContentView(list: $navigationModel.groceryList)
            }
            #if os(macOS)
            .toolbar {
                GroceryListButton(isActive: $showGroceryList)
            }
            #endif
            .onAppear {
                if let jsonData = model {
                    navigationModel.jsonData = jsonData
                }
                model = navigationModel.jsonData
            }
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#Preview {
    ContentView()
}
