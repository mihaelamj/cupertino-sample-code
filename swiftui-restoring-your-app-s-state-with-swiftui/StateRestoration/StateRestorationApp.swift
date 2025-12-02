/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application and scene for this sample.
*/

import SwiftUI

@main
struct StateRestorationApp: App {
    private var productsModel = ProductsModel()
    var body: some Scene {
        WindowGroup("Products", id: "Products.viewer") {
            ContentView()
                .environmentObject(productsModel)
        }
    }
}
