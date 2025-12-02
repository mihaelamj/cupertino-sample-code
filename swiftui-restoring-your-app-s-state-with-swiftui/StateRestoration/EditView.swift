/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The edit view for editing a particular product.
*/

import SwiftUI

struct EditView: View {
    // The data model for storing all the products.
    @EnvironmentObject var productsViewModel: ProductsModel
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var product: Product

    // Whether to use product or saved values.
    @SceneStorage("EditView.useSavedValues") var useSavedValues = true
    
    // Restoration values for the edit fields.
    @SceneStorage("EditView.editTitle") var editName: String = ""
    @SceneStorage("EditView.editYear") var editYear: String = ""
    @SceneStorage("EditView.editPrice") var editPrice: String = ""
    
    // Use different width and height for info view between compact and non-compact size classes.
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    var imageWidth: CGFloat {
        horizontalSizeClass == .compact ? 100 : 280
    }
    var imageHeight: CGFloat {
        horizontalSizeClass == .compact ? 80 : 260
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("")) {
                    HStack {
                        Spacer()
                        Image(product.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: imageWidth, height: imageHeight)
                            .clipped()
                        Spacer()
                    }
                }

                Section(header: Text("NameTitle")) {
                    TextField("AccessibilityNameField", text: $editName)
                }
                Section(header: Text("YearTitle")) {
                    TextField("AccessibilityYearField", text: $editYear)
                        .keyboardType(.numberPad)
                }
                Section(header: Text("PriceTitle")) {
                    TextField("AccessibilityPriceField", text: $editPrice)
                        .keyboardType(.decimalPad)
                }
            }

            .navigationBarTitle(Text("EditProductTitle"), displayMode: .inline)
            
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("CancelTitle", action: cancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("DoneTitle", action: done)
                        .disabled(editName.isEmpty)
                }
            }
        }
        
        .onAppear {
            // Decide whether or not to use the scene storage for restoration.
            if useSavedValues {
                editName = product.name
                editYear = String(product.year)
                editPrice = String(product.price)
                useSavedValues = false // Until we're dismissed, use sceneStorage values
            }
        }
    }

    func cancel() {
        dismiss()
    }
    
    func done() {
        save()
        dismiss()
    }
    
    func dismiss() {
        useSavedValues = true
        self.presentationMode.wrappedValue.dismiss()
    }

    // User tapped the Done button to commit the product edit.
    func save() {
        product.name = editName
        product.year = Int(editYear)!
        product.price = Double(editPrice)!
        productsViewModel.save()
    }
}

struct EditView_Previews: PreviewProvider {
    static var previews: some View {
        let product = Product(
            identifier: UUID(uuidString: "fa542e3d-4895-44b6-942f-e112101d5160")!,
            name: "Cherries",
            imageName: "Cherries",
            year: 2015,
            price: 10.99)
        EditView(product: product)
    }
}
