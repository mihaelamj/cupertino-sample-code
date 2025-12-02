/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that manages main content of the HoagiesApp.
*/

import SwiftUI

struct ContentView: View {
    
    @Bindable var shared: MemoryLogger
    
    @State var showOrder = false
    
    var body: some View {
        Color.cornflowerBlue
        .ignoresSafeArea()
        .overlay {
            VStack {
                Text("The Hoagie Shop")
                    .font(.title)
                    .padding()
                if OrderingService.service.inCarPlay {
                    Text("You are in CarPlay.\nUse quick ordering with the CarPlay screen.\nDon't use your phone while driving.")
                        .foregroundStyle(Color.red)
                        .font(.title)
                        .padding()
                        .multilineTextAlignment(.center)
                } else {
                    NavigationStack {
                        HStack(content: {
                            ForEach(TestHoagieData.testMapItems()) { item in
                                NavigationLink(
                                    item.mapItem.name ?? "Un-named Hoagie Shop",
                                    destination: PickBreadView(hoagie: TestHoagieData.Hoagie()))
                                    .padding()
                                    .border(Color.cornflowerBlue, width: customBorderWidth)
                            }
                        })
                    }
                    .background {
                        Color.pink
                    }
                }
                Divider()
                Text("Debugging")
                List {
                    ForEach(shared.events) { event in
                        Text(event.text)
                    }
                }
            }
        }
        .sheet(isPresented: $showOrder, content: {
            OrderStatusView(state: OrderingService.service.orderState)
        })
        .onOpenURL(perform: { url in
//          This URL is from the widget or a Live Activity. Determine whether there's an order to show.
            if OrderStatusAttributes.valueForState(value: OrderingService.service.orderState) != .unknown {
                showOrder = true
            }
        })
        .tint(.cornflowerBlue)
    }
}

struct PickBreadView: View {
    
    @State var hoagie: TestHoagieData.Hoagie
    
    var body: some View {
        VStack(content: {
            Text("Pick a Bread or tap '⏭️'")
            HStack(content: {
                Text("🥯")
                    .padding()
                    .border(hoagie.bread == ("🥯") ? Color.green : Color.black, width: customBorderWidth)
                    .onTapGesture {
                        hoagie.bread = hoagie.bread == "🥯" ? "" : "🥯"
                    }
                Text("🥖")
                    .padding()
                    .border(hoagie.bread == ("🥖") ? Color.green : Color.black, width: customBorderWidth)
                    .onTapGesture {
                        hoagie.bread = hoagie.bread == "🥖" ? "" : "🥖"
                    }
                Text("🫓")
                    .padding()
                    .border(hoagie.bread == ("🫓") ? Color.green : Color.black, width: customBorderWidth)
                    .onTapGesture {
                        hoagie.bread = hoagie.bread == "🫓" ? "" : "🫓"
                    }
                Text("🥐")
                    .padding()
                    .border(hoagie.bread == ("🥐") ? Color.green : Color.black, width: customBorderWidth)
                    .onTapGesture {
                        hoagie.bread = hoagie.bread == "🥐" ? "" : "🥐"
                    }
                Text("🍞")
                    .padding()
                    .border(hoagie.bread == ("🍞") ? Color.green : Color.black, width: customBorderWidth)
                    .onTapGesture {
                        hoagie.bread = hoagie.bread == "🍞" ? "" : "🍞"
                    }
            })
            .font(.title)
            NavigationLink("⏭️") {
                PickMeatsView(hoagie: hoagie)
            }
            .padding()
            .border(Color.cornflowerBlue, width: customBorderWidth)
        })
    }
}

struct PickMeatsView: View {
    
    @State var hoagie: TestHoagieData.Hoagie
    
    var body: some View {
        VStack(content: {
            Text("Add your Meats or tap '⏭️'")
            HStack(content: {
                Text("🐷")
                    .padding()
                    .border(hoagie.meats.contains("🐷") == true ? Color.green : Color.black, width: customBorderWidth)
                    .onTapGesture {
                        if let index = hoagie.meats.firstIndex(of: "🐷") {
                            hoagie.meats.remove(at: index)
                        } else {
                            hoagie.meats.append("🐷")
                        }
                    }
                Text("🦃")
                    .padding()
                    .border(hoagie.meats.contains("🦃") == true ? Color.green : Color.black, width: customBorderWidth)
                    .onTapGesture {
                        if let index = hoagie.meats.firstIndex(of: "🦃") {
                            hoagie.meats.remove(at: index)
                        } else {
                            hoagie.meats.append("🦃")
                        }
                    }
            })
            .font(.largeTitle)
            .padding()
            NavigationLink("⏭️") {
                CheeseView(hoagie: hoagie)
            }
            .padding()
            .border(Color.cornflowerBlue, width: customBorderWidth)
        })
    }
}

struct CheeseView: View {
    
    @State var hoagie: TestHoagieData.Hoagie
    
    var body: some View {
        VStack(content: {
            Text("Want Cheese??? If not, tap '⏭️'")
            HStack(content: {
                Text("🧀")
                    .padding()
                    .border(hoagie.cheese == "🧀" ? Color.green : Color.black, width: customBorderWidth)
                    .onTapGesture {
                        hoagie.cheese = hoagie.cheese == "🧀" ? "" : "🧀"
                    }
            })
            .font(.largeTitle)
            .padding()
            NavigationLink("⏭️") {
                PickVeggiesView(hoagie: hoagie)
            }
            .padding()
            .border(Color.cornflowerBlue, width: customBorderWidth)
        })
    }
}

struct PickVeggiesView: View {
    
    @State var hoagie: TestHoagieData.Hoagie
    
    var body: some View {
        VStack(content: {
            Text("Add your Veggies or tap '⏭️'")
            HStack(content: {
                Text("🥬")
                    .padding()
                    .border(hoagie.vegetables.contains("🥬") == true ? Color.green : Color.black, width: customBorderWidth)
                    .onTapGesture {
                        if let index = hoagie.vegetables.firstIndex(of: "🥬") {
                            hoagie.vegetables.remove(at: index)
                        } else {
                            hoagie.vegetables.append("🥬")
                        }
                    }
                Text("🍅")
                    .padding()
                    .border(hoagie.vegetables.contains("🍅") == true ? Color.green : Color.black, width: customBorderWidth)
                    .onTapGesture {
                        if let index = hoagie.vegetables.firstIndex(of: "🍅") {
                            hoagie.vegetables.remove(at: index)
                        } else {
                            hoagie.vegetables.append("🍅")
                        }
                    }
                Text("🧅")
                    .padding()
                    .border(hoagie.vegetables.contains("🧅") == true ? Color.green : Color.black, width: customBorderWidth)
                    .onTapGesture {
                        if let index = hoagie.vegetables.firstIndex(of: "🧅") {
                            hoagie.vegetables.remove(at: index)
                        } else {
                            hoagie.vegetables.append("🧅")
                        }
                    }
            })
            .font(.largeTitle)
            NavigationLink("⏭️") {
                PickDressingsView(hoagie: hoagie)
            }
            .padding()
            .border(Color.cornflowerBlue, width: customBorderWidth)
        })
    }
}

struct PickDressingsView: View {
    
    @State var hoagie: TestHoagieData.Hoagie
    
    var body: some View {
        VStack(content: {
            Text("Add your Dressings or tap '⏭️'")
            HStack(content: {
                Text("🧂")
                    .padding()
                    .border(hoagie.dressings.contains("🧂") == true ? Color.green : Color.black, width: customBorderWidth)
                    .onTapGesture {
                        if let index = hoagie.dressings.firstIndex(of: "🧂") {
                            hoagie.dressings.remove(at: index)
                        } else {
                            hoagie.dressings.append("🧂")
                        }
                    }
                Text("🌶️")
                    .padding()
                    .border(hoagie.dressings.contains("🌶️") == true ? Color.green : Color.black, width: customBorderWidth)
                    .onTapGesture {
                        if let index = hoagie.dressings.firstIndex(of: "🌶️") {
                            hoagie.dressings.remove(at: index)
                        } else {
                            hoagie.dressings.append("🌶️")
                        }
                    }
                Text("🧈")
                    .padding()
                    .border(hoagie.dressings.contains("🧈") == true ? Color.green : Color.black, width: customBorderWidth)
                    .onTapGesture {
                        if let index = hoagie.dressings.firstIndex(of: "🧈") {
                            hoagie.dressings.remove(at: index)
                        } else {
                            hoagie.dressings.append("🧈")
                        }
                    }
            })
            .font(.largeTitle)
            NavigationLink("⏭️") {
                SummaryView(hoagie: hoagie)
            }
            .padding()
            .border(Color.cornflowerBlue, width: customBorderWidth)
        })
    }
}

struct SummaryView: View {
    
    @State var hoagie: TestHoagieData.Hoagie
    @State var errorOnOrder = false
    
    var body: some View {
        VStack {
            Text(hoagie.bread)
            Text(hoagie.cheese)
            Text(hoagie.meats.joined(separator: ""))
            Text(hoagie.vegetables.joined(separator: ""))
            Text(hoagie.dressings.joined(separator: ""))
            Button("Order Now") {
                do {
                    MemoryLogger.shared.appendEvent("Order Button Tapped")
                    try OrderingService.placeOrder(
                        hoagieOrder: .init(
                            orderItems: [
                                hoagie.bread,
                                hoagie.cheese,
                                hoagie.meats.joined(separator: ""),
                                hoagie.vegetables.joined(separator: ""),
                                hoagie.dressings.joined(separator: "")
                            ],
                            typeOfOrder: "App",
                            location: TestHoagieData.testMapItems().randomElement()!.mapItem.name!))
                } catch {
                    MemoryLogger.shared.appendEvent(error.localizedDescription)
                    errorOnOrder = true
                }
            }
            .alert("Error on Order", isPresented: $errorOnOrder, actions: {
                Text("Check the code for the error and try again.")
            })
            .padding()
            .border(Color.green, width: customBorderWidth)
        }
    }
}
