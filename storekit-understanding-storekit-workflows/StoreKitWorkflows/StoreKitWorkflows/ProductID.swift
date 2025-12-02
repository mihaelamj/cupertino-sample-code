/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Product identifiers that the app uses.
*/

enum ProductID: String {
    case consumable = "consumable"
    case consumablePack = "consumable_pack"

    case nonconsumable = "nonconsumable"

    case subscriptionMonthly = "subscription_monthly"
    case subscriptionYearly = "subscription_yearly"
    case subscriptionPremiumYearly = "premium_subscription_yearly"
}

// Organize product IDs into groups, for convenient use elsewhere in the code.
extension ProductID {
    static let consumables = [
        ProductID.consumable.rawValue,
        ProductID.consumablePack.rawValue
    ]
    static let nonconsumables = [ProductID.nonconsumable.rawValue]
    static let subscriptions = [
        ProductID.subscriptionMonthly.rawValue,
        ProductID.subscriptionYearly.rawValue,
        ProductID.subscriptionPremiumYearly.rawValue
    ]
    static let all = consumables + nonconsumables + subscriptions
}
