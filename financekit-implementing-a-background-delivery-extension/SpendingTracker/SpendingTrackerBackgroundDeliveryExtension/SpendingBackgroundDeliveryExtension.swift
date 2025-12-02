/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension for updating the widget.
*/

import FinanceKit
import WidgetKit

@main
struct SpendingBackgroundDeliveryExtension: BackgroundDeliveryExtension {
    let storage: Storage
    
    init() {
        self.storage = Storage()
    }
    
    func didReceiveData(for types: [FinanceStore.BackgroundDataType]) async {
        // Skip accounts and account balances.
        if types.contains(.transactions) {
            do {
                // Calculate the total spending over the past week.
                let total: Decimal = try await FinanceUtilities.calculateWeeklySpendingTotal()
                
                // Save the total.
                storage.setWeeklySpending(total)
                
                // Update the widget.
                WidgetCenter.shared.reloadAllTimelines()
            } catch {
                print("Error updating transaction total: \(error)")
            }
        }
    }
    
    func willTerminate() async {}
}
