/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Coffee drink options that the player can brew.
*/

import Foundation

struct CoffeeDrink {
    let drinkType: DrinkType
    let temperature: Temp
    let milk: MilkType
    let flavors: [Flavor]

    enum Temp: String, CaseIterable, Identifiable {
        case hot
        case iced

        var id: Self { self }
    }

    enum DrinkType: String, CaseIterable, Identifiable {
        case latte
        case dripCoffee
        case espresso
        case macciato
        case cappucino
        case cortado
        case tea
        case hotChocolate

        var id: Self { self }
    }

    enum MilkType: String, CaseIterable, Identifiable {
        case none
        case twoPercent
        case whole
        case halfAndHalf
        case almond
        case soy
        case oat
        case skim

        var id: Self { self }
    }

    enum Flavor: String, CaseIterable, Identifiable {
        case lavendar
        case vanilla
        case spiceCookie
        case mocha
        case caramel
        case hazelnut
        case ube
        case chai
        case chamomile

        var id: Self { self }
    }
}
