/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
In this view the player can pick drink options and brew a drink.
*/

import SwiftUI

struct CoffeeOrderView: View {
    let orderReady: (CoffeeDrink) -> Void

    @State var drinkType: CoffeeDrink.DrinkType = .dripCoffee
    @State var temp: CoffeeDrink.Temp = .hot
    @State var milk: CoffeeDrink.MilkType = .none
    @State var flavorSet: Set<CoffeeDrink.Flavor> = []

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Group {
                    VStack {
                        Text("Drink")
                            .fontWeight(.bold)
                            .foregroundStyle(.darkBrown)
                        
                        Picker("", selection: $drinkType) {
                            ForEach(CoffeeDrink.DrinkType.allCases) { drink in
                                Text(drink.rawValue.capitalized)
                            }
                        }
                        .tint(.black)
                    }
                }

                Group {
                    VStack {
                        Text("Temperature")
                            .fontWeight(.bold)
                            .foregroundStyle(.darkBrown)
                        
                        Picker("", selection: $temp) {
                            ForEach(CoffeeDrink.Temp.allCases) { item in
                                Text(item.rawValue.capitalized)
                            }
                        }
                        .tint(.black)
                    }
                }

                Group {
                    VStack {
                        Text("Milk")
                            .fontWeight(.bold)
                            .foregroundStyle(.darkBrown)
                        
                        Picker("", selection: $milk) {
                            ForEach(CoffeeDrink.MilkType.allCases) { item in
                                Text(item.rawValue.capitalized)
                            }
                        }
                        .tint(.black)
                    }
                }
            }

            LazyVGrid(columns: columns) {
                ForEach(CoffeeDrink.Flavor.allCases) { item in
                    Button {
                        toggleFlavor(item)
                    } label: {
                        Image(systemName: flavorIsSelected(item) ? "square.fill" : "square")
                            .foregroundStyle(.darkBrown)
                        Text(item.rawValue)
                        Spacer()
                    }
                    .buttonStyle(.plain)
                }
            }
            .modifier(GameBoxStyle())

            Button {
                orderReady(brewDrink())
            } label: {
                Spacer()
                Text("Brew drink!")
                    .fontWeight(.bold)
                    .foregroundStyle(.darkBrown)
                Spacer()
            }
            .buttonStyle(.plain)
            .modifier(GameBoxStyle())
        }
        .modifier(GameBoxStyle())
    }

    func toggleFlavor(_ flavor: CoffeeDrink.Flavor) {
        if flavorSet.contains(flavor) {
            flavorSet.remove(flavor)
        } else {
            flavorSet.insert(flavor)
        }
    }

    func flavorIsSelected(_ flavor: CoffeeDrink.Flavor) -> Bool {
        return flavorSet.contains(flavor)
    }

    func brewDrink() -> CoffeeDrink {
        return CoffeeDrink(
            drinkType: drinkType,
            temperature: temp,
            milk: milk,
            flavors: Array(flavorSet)
        )
    }
}

#Preview {
    CoffeeOrderView { brew in
        print("Brewed", brew)
    }
}
