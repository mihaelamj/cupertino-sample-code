/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view for this sample hosting the LazyVGrid or collection view.
*/

import SwiftUI

struct ContentView: View {
    // The data model for storing all the products.
    @EnvironmentObject var productsModel: ProductsModel
    
    // Used for detecting when this scene is backgrounded and isn't currently visible.
    @Environment(\.scenePhase) private var scenePhase

    // The currently selected product, if any.
    @SceneStorage("ContentView.selectedProduct") private var selectedProduct: String?
    
    let columns = Array(repeating: GridItem(.adaptive(minimum: 94, maximum: 120)), count: 3)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(productsModel.products) { product in
                        NavigationLink(destination: DetailView(product: product, selectedProductID: $selectedProduct),
                                       tag: product.id.uuidString,
                                       selection: $selectedProduct) {
                            StackItemView(itemName: product.name, imageName: product.imageName)
                        }
                        .padding(8)
                        .buttonStyle(PlainButtonStyle())
                        
                        .onDrag {
                            /** Register the product user activity as part of the drag provider which
                                will  create a new scene when dropped to the left or right of the iPad screen.
                            */
                            let userActivity = NSUserActivity(activityType: DetailView.productUserActivityType)
                            
                            let localizedString = NSLocalizedString("DroppedProductTitle", comment: "Activity title with product name")
                            userActivity.title = String(format: localizedString, product.name)
                            
                            userActivity.targetContentIdentifier = product.id.uuidString
                            try? userActivity.setTypedPayload(product)
                            
                            return NSItemProvider(object: userActivity)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("ProductsTitle")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        
        .onContinueUserActivity(DetailView.productUserActivityType) { userActivity in
            if let product = try? userActivity.typedPayload(Product.self) {
                selectedProduct = product.id.uuidString
            }
        }
        .onChange(of: scenePhase) { newScenePhase in
            if newScenePhase == .background {
                // Make sure to save any unsaved changes to the products model.
                productsModel.save()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(ProductsModel())
    }
}

// The view used to describe each product in the LazyVGrid.
struct StackItemView: View {
    var itemName: String
    var imageName: String
    var body: some View {
        VStack {
            Image(imageName)
                .resizable()
                .font(.title)
                .scaledToFit()
                .cornerRadius(8.0)
            Text("\(itemName)")
                .font(.caption)
        }
    }
}

