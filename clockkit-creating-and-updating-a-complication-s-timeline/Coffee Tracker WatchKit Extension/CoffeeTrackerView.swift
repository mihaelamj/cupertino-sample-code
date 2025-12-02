/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view where users can add drinks or view the current amount of caffeine they have drunk.
*/

import SwiftUI

// The Coffee Tracker app's main view.
struct CoffeeTrackerView: View {
    
    @EnvironmentObject var coffeeData: CoffeeData
    @State var showDrinkList = false
    
    // Lay out the view's body.
    var body: some View {
        
        // Use a timeline view to update the caffeine dose every minute.
        // This works both when the user's interacting with the app,
        // and when their watch is in Always On mode.
        TimelineView(.everyMinute) { context in
            VStack {
                
                // Display the current amount of caffeine in the user's body.
                Text(coffeeData.mgCaffeineString(atDate: context.date) + " mg")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(colorForCaffeineDose(atDate: context.date))
                Text("Current Caffeine Dose")
                    .font(.footnote)
                Divider()
                
                // Display how much the user has drunk today,
                // using the equivalent number of 8 oz. cups of coffee.
                Text(coffeeData.totalCupsTodayString + " cups")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(colorForDailyDrinkCount())
                Text("Equivalent Drinks Today")
                    .font(.footnote)
                Spacer()
                
                // Display a button that lets the user record new drinks.
                Button(action: { self.showDrinkList.toggle() }) {
                    Image("add-coffee")
                        .renderingMode(.template)
                }
            }
        }
        .sheet(isPresented: $showDrinkList) {
            DrinkListView().environmentObject(self.coffeeData)
        }
    }
    
    // MARK: - Private Methods
    // Calculate the color based on the amount of caffeine currently in the user's body.
    private func colorForCaffeineDose(atDate date: Date) -> Color {
        // Get the current amount of caffeine in the user's body.
        let currentDose = coffeeData.mgCaffeine(atDate: date)
        return Color(coffeeData.color(forCaffeineDose: currentDose))
    }
    
    // Calculate the color based on the number of drinks consumed today.
    private func colorForDailyDrinkCount() -> Color {
        // Get the number of cups drank today.
        let cups = coffeeData.totalCupsToday
        return Color(coffeeData.color(forTotalCups: cups))
    }
}

// Configure a preview of the coffee tracker view.
struct CoffeeTrackerView_Previews: PreviewProvider {
    static var previews: some View {
        CoffeeTrackerView()
            .environmentObject(CoffeeData.shared)
    }
}
