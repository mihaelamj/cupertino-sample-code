/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The detail view describing the product details.
*/

import SwiftUI

struct DetailView: View {
    // The user activity type representing this view.
    static let productUserActivityType = "com.example.apple-samplecode.staterestore.product"
    
    @ObservedObject var product: Product
    @Binding var selectedProductID: String?
    
    enum Tabs: String {
        case detail
        case photo
    }
    // State restoration: the selected tab in TabView.
    @SceneStorage("DetailView.selectedTab") private var selectedTab = Tabs.detail
    
    // State restoration: the presentation state for the EditView.
    @SceneStorage("DetailView.showEditView") private var showEditView = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            InfoTabView(product: product)
            .tabItem {
                Label("DetailTitle", systemImage: "info.circle")
            }
            .tag(Tabs.detail)
            
            Image(product.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .border(Color("borderColor"), width: 1.0)
                .padding()
            .tabItem {
                Label("PhotoTitle", systemImage: "photo")
            }
            .tag(Tabs.photo)
        }
        
        .sheet(isPresented: $showEditView) {
            EditView(product: product)
        }

        .toolbar {
            ToolbarItem {
                Button("EditTitle", action: { showEditView.toggle() })
            }
        }
               
        // The described activity for this view.
        .userActivity(DetailView.productUserActivityType,
                      isActive: product.id.uuidString == selectedProductID) { userActivity in
            describeUserActivity(userActivity)
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func describeUserActivity(_ userActivity: NSUserActivity) {
        let returnProduct: Product! // Will be set to existing from activity, or new instance.
        if let activityProduct = try? userActivity.typedPayload(Product.self) {
            /** Use product in the activity.
                Make sure advertised Product contains name/id that we are advertising from the current Product.
            */
            returnProduct = Product(identifier: product.id,
                                    name: product.name,
                                    imageName: activityProduct.imageName,
                                    year: activityProduct.year,
                                    price: activityProduct.price
            )
        } else {
            returnProduct = product // No product in activity, so start with existing.
        }

        let localizedString =
            NSLocalizedString("ShowProductTitle", comment: "Activity title with product name")
        userActivity.title = String(format: localizedString, product.name)
        
        userActivity.isEligibleForHandoff = true
        userActivity.isEligibleForSearch = true
        userActivity.targetContentIdentifier = returnProduct.id.uuidString
        try? userActivity.setTypedPayload(returnProduct)
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        let product = Product(
            identifier: UUID(uuidString: "fa542e3d-4895-44b6-942f-e112101d5160")!,
            name: "Cherries",
            imageName: "Cherries",
            year: 2015,
            price: 10.99)
        DetailView(product: product, selectedProductID: .constant(nil))
    }
}
