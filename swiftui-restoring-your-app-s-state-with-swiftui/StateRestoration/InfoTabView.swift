/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view used to describe the info view (first tab).
*/

import SwiftUI

struct InfoTabView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @ObservedObject var product: Product
    
    // Use different width and height for info view between compact and non-compact size classes.
    var width: CGFloat {
        horizontalSizeClass == .compact ? 330 : 420
    }
    var height: CGFloat {
        horizontalSizeClass == .compact ? 360 : 460
    }
    
    var body: some View {
        VStack(alignment: .center) {
            InfoView(product: product)
                .frame(width: width, height: height)
            Spacer()
        }
        .padding()
    }
}

struct InfoTabView_Previews: PreviewProvider {
    static var previews: some View {
        let product = Product(
            identifier: UUID(uuidString: "fa542e3d-4895-44b6-942f-e112101d5160")!,
            name: "Cherries",
            imageName: "Cherries",
            year: 2015,
            price: 10.99)
        InfoTabView(product: product)
    }
}

// MARK: - InfoView

struct InfoView: View {
    @ObservedObject var product: Product
    
    @Environment(\.currencyFormatter) var currencyFormatter
    @Environment(\.numberFormatter) var numberFormatter

    var body: some View {
        VStack {
            VStack {
                Spacer(minLength: 20)

                Row("Name:") {
                    Text(product.name)
                }
                Row("Year:") {
                    TextField("Year", value: $product.year, formatter: numberFormatter)
                }
                Row("Price:") {
                    TextField("Price", value: $product.price, formatter: currencyFormatter)
                }
                Image(product.imageName)
                    .resizable()
                    .scaledToFit()
                    .border(Color("borderColor"), width: 1.0)
                    .padding()
            }
            .background(Color.gray.opacity(0.1))

            Spacer()
        }
        .frame(maxWidth: 360)
        .padding(.top)
    }
    
    struct Row<Label: View>: View {
        var key: LocalizedStringKey
        var label: Label

        init(_ key: LocalizedStringKey, @ViewBuilder label: () -> Label) {
            self.key = key
            self.label = label()
        }

        var body: some View {
            HStack {
                Text(key)
                    .foregroundColor(Color.gray)
                    .frame(width: 150, alignment: .trailing)
                label
                Spacer()
            }
            .padding(5)
        }
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        let product = Product(
            identifier: UUID(uuidString: "fa542e3d-4895-44b6-942f-e112101d5160")!,
            name: "Cherries",
            imageName: "Cherries",
            year: 2015,
            price: 10.99)
        InfoView(product: product)
    }
}
