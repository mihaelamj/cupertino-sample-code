/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The App Intent for `OrderSoup`.
*/

import Foundation
import AppIntents
import CoreLocation
import SwiftUI
import Intents
import SoupKit

/// - Tag: CustomIntentMigratedAppIntent
@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct OrderSoup: AppIntent, CustomIntentMigratedAppIntent {
    static let intentClassName = "OrderSoupIntent"

    static var title: LocalizedStringResource = "Order Soup"
    static var description = IntentDescription("Order a soup")

    @Parameter(title: "Soup")
    var soup: SoupAppEntity

    @Parameter(title: "Quantity", default: 1)
    var quantity: Int?

    @Parameter(title: "Toppings")
    var toppings: [ToppingAppEntity]?

    @Parameter(title: "Order Type", default: .pickup)
    var orderType: OrderTypeAppEnum?

    @Parameter(title: "Delivery Location")
    var deliveryLocation: CLPlacemark?

    @Parameter(title: "Store Location", optionsProvider: CLPlacemarkOptionsProvider())
    var storeLocation: CLPlacemark?

    /// - Tag: dynamicOptionsProvider
    struct CLPlacemarkOptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [CLPlacemark] {
            Order.storeLocations
        }
    }
    
    static var parameterSummary: some ParameterSummary {
        Switch(\.$orderType) {
            Case(.delivery) {
                Summary("Order \(\.$quantity) \(\.$soup) for \(\.$orderType) to \(\.$deliveryLocation)") {
                    \.$toppings
                }
            }
            Case(.pickup) {
                Summary("Order \(\.$quantity) \(\.$soup) for \(\.$orderType) from \(\.$storeLocation)") {
                    \.$toppings
                }
            }
            DefaultCase {
                Summary("Order \(\.$quantity) \(\.$soup) for \(\.$orderType)") {
                    \.$toppings
                }
            }
        }
    }
    
    /// - Tag: perform
    func perform() async throws -> some ProvidesDialog & ShowsSnippetView & ReturnsValue<OrderDetailsAppEntity> {
            // Want to confirm if quantity is greater than five and return "out of stock" if the quantity ordered exceeds the amount available.
            let menuManager = SoupMenuManager()
            let searchTerm = self.soup.displayString
            let menuItem = menuManager.findItems(exactlyMatching: [.available, .regularItem], [.available, .dailySpecialItem], searchTerm: searchTerm)
            let quantity = self.quantity ?? 0
            if quantity > 5 {
                let dialogResponse = IntentDialog.quantityParameterConfirmation(quantity: quantity)
                let confirmed = try await self.$quantity.requestConfirmation(for: quantity, dialog: dialogResponse)
                
                if !confirmed {
                    return .result(value: OrderDetailsAppEntity(), dialog: IntentDialog.responseCancel())
                }
            }
            if quantity > menuItem[0].itemsInStock {
                let errorPrompt = OrderSoupError.notEnoughInStock(quantity ).localizedStringResource
                            return .result(value: OrderDetailsAppEntity(), dialog: IntentDialog(errorPrompt))
            }
            // Prompt for store location or delivery location if the order type is configured to ask each time.
            if self.orderType == .pickup && self.storeLocation == nil {
                self.storeLocation = try await self.$storeLocation.requestDisambiguation(among: Order.storeLocations)
            }
            if self.orderType == .delivery {
                  guard deliveryLocation != nil else {
                      throw $deliveryLocation.needsValueError(IntentDialog.deliveryLocationParameterPrompt)
                  }
            }
            // Create an order entry to place the order.
            let orderEntry = Order(from: self)
            //  For the success case, indicate a wait time so the person knows when their soup order will be ready.
            //  This sample uses a hard-coded value, but your implementation could use a time returned by a server.
            let orderDate = Date()
            let readyDate = Date(timeInterval: 10 * 60, since: orderDate) // 10 minutes
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .full
            let totalCurrencyAmount = IntentCurrencyAmount(
                amount: NSDecimalNumber(decimal: orderEntry.total) as Decimal,
                currencyCode: NumberFormatter.currencyFormatter.currencyCode)
        
            try await requestConfirmation(
                result:
                    .result(
                        value: OrderDetailsAppEntity(),
                        dialog: IntentDialog.orderConfirmation(total: totalCurrencyAmount),
                        view: OrderPreviewView(order: orderEntry, orderIntent: self)),
                confirmationActionName: .order,
                showPrompt: false)
            
            if let formattedWaitTime = DateComponentsFormatter().string(from: orderDate, to: readyDate) {
                return .result(value: OrderDetailsAppEntity(/* Use the result to combine with other shortcuts. */),
                               dialog: IntentDialog.responseSuccess(total: totalCurrencyAmount, soup: self.soup, waitTime: formattedWaitTime),
                               view: OrderConfirmedView(order: orderEntry, orderIntent: self))
            } else {
                // A fallback success code with a less specific message string.
                return .result(value: OrderDetailsAppEntity(/* Use the result to combine with other shortcuts. */),
                               dialog: IntentDialog.responseSuccessReadySoon(total: totalCurrencyAmount, soup: self.soup),
                               view: OrderConfirmedView(order: orderEntry, orderIntent: self))
            }
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
enum OrderSoupError: Error, CustomLocalizedStringResourceConvertible {
    case notEnoughInStock(Int)
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .notEnoughInStock(let quantity):
            return "You asked for \(quantity) soup, but we don't have that many in stock."
        }
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct OrderPreviewView: View {

    let order: Order
    let orderIntent: OrderSoup
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(order.menuItem.iconImageName)
                .cornerRadius(8)
                .fixedSize()
            VStack(alignment: .leading) {
                Text(order.menuItem.localizedName())
                    .fontWeight(.semibold)
                Spacer(minLength: 2)
                Text("\(order.quantity) @ $\(NSDecimalNumber(decimal: order.menuItem.price).stringValue)")
                    .foregroundColor(.gray)
                ForEach(order.menuItemToppings.sorted { $0.rawValue < $1.rawValue }) { topping in
                     Text(topping.rawValue).foregroundColor(.gray)
                }
                if orderIntent.orderType == .delivery {
                    Text("Delivery to \(orderIntent.deliveryLocation?.name ?? "")")
                        .foregroundColor(.gray)
                } else {
                    Text("Pick up from \(orderIntent.storeLocation?.name ?? "")")
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("Total:")
                    Text("$\(NSDecimalNumber(decimal: order.total).stringValue)")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding([.horizontal])
        .padding([.vertical], 6)
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct OrderConfirmedView: View {

    let order: Order
    let orderIntent: OrderSoup
    var body: some View {
        HStack {
            Image(order.menuItem.iconImageName)
            VStack {
                Text(order.menuItem.localizedName())
                    .font(.body)
                    .fontWeight(.semibold)
                Spacer(minLength: 2)
                Text("Order Confirmed")
                    .font(.subheadline)
                    .foregroundColor(.black)
                Text("10 minutes")
                    .font(.subheadline)
                    .foregroundColor(.black)
                if orderIntent.orderType == .delivery {
                    Text("Delivery to \(orderIntent.deliveryLocation?.name ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text("Pick up from \(orderIntent.storeLocation?.name ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        Image(systemName: "checkmark.circle.fill")
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
extension Order {

     init(from entity: OrderSoup) {
         let menuManager = SoupMenuManager()
         let menuItem = menuManager.findItems(
            exactlyMatching: [.available, .regularItem], [.available, .dailySpecialItem],
            searchTerm: entity.soup.displayString)
         let quantity = entity.quantity
         let rawToppings = entity.toppings?.compactMap { (topping) -> MenuItemTopping? in
             return MenuItemTopping(rawValue: topping.id)
         } ?? [MenuItemTopping]()
   
         switch entity.orderType {
            case .none:
             self.init(quantity: quantity ?? 1, menuItem: menuItem[0], menuItemToppings: Set(rawToppings))
            case .pickup:
             self.init(quantity: quantity ?? 1, menuItem: menuItem[0], menuItemToppings: Set(rawToppings))
            case .delivery:
             self.init(quantity: quantity ?? 1, menuItem: menuItem[0], menuItemToppings: Set(rawToppings))
         }
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
    static var deliveryLocationParameterPrompt: Self {
        "Where would you like your order delivered?"
    }
    static func quantityParameterConfirmation(quantity: Int) -> Self {
        "Just to confirm, you would like to order \(quantity) soups?"
    }
    static func storeLocationParameterConfirmation(storeLocation: CLPlacemark) -> Self {
        "Just to confirm, you wanted ‘\(storeLocation)’?"
    }
    static func orderConfirmation(total: IntentCurrencyAmount) -> Self {
        "Your total is \(total). ready to order?"
    }
    static func responseSuccess(total: IntentCurrencyAmount, soup: SoupAppEntity, waitTime: String) -> Self {
        "Your total is \(total). Your \(soup) order will be ready in \(waitTime)."
    }
    static func responseFailureOutOfStock(soup: SoupAppEntity) -> Self {
        "Sorry, \(soup) is out of stock."
    }
    static func responseSuccessReadySoon(total: IntentCurrencyAmount, soup: SoupAppEntity) -> Self {
        "Your total is \(total). Your \(soup) order will be ready soon."
    }
    static func responseCancel() -> Self {
          "OK, Order Cancelled"
    }
}

