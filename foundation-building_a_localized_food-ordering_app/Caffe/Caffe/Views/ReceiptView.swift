/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that shows the receipt for an order, including localized tip, total, and a thank-you message.
*/

import SwiftUI

struct ReceiptView: View {
    
    @State private var tip: Double = 0.15
    private let order: Order
    private var total: Decimal {
        order.totalPrice * (1.0 + Decimal(tip))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    Section(header: Spacer(), content: {
                        ForEach(order.items) { (item: OrderItem) in
                            HStack {
                                Text(orderDescription(for: item))
                                Spacer()
                                Text(item.price.formatted(.currency(code: "USD")))
                            }
                        }
                    })

                    Section {
                        HStack {
                            Text("Tip")
                            Spacer()
                            TextField("Amount", value: $tip, format: .percent)
                                .multilineTextAlignment(.trailing)
                        }
                    }

                    Section {
                        HStack {
                            Text("Total")
                            Spacer()
                            Text(total.formatted(.currency(code: "USD")))
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle(Text("Receipt"))
                .padding([.top, .bottom], 20)

                Text("**Thank you!**")
                Text("_Please visit our [website](https://www.example.com)._")
                    .padding([.leading, .trailing, .bottom], 40)
            }
        }
    }
    
    init(withOrder order: Order) {
        self.order = order
    }
    
    private func orderDescription(for item: OrderItem) -> AttributedString {
        AttributedString(localized: "^[\(item.quantity) \(item.foodSize.localizedName) \(item.foodItem.localizedName)](inflect: true)",
                         comment: "Item entry on receipt")
    }
}

struct ReceiptView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiptView(withOrder: Order())
    }
}
