/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that shows a transaction list and spending summary.
*/

import FinanceKit
import SwiftUI
import WidgetKit

struct ContentView: View {
    @State var weeklySpendingTotal: Decimal = 0
    @State var transactions = [TransactionModel]()
    
    private let storage = Storage()
    
    var body: some View {
        List {
            Section("Weekly Spend") {
                Text("\(formattedTotal)")
                    .font(.largeTitle)
                    .fontDesign(.rounded)
                    .fontWeight(.bold)
            }
            Section("This week's transactions") {
                ForEach(transactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
        .task {
            do {
                // First, check whether the user authorized access to their data.
                if try await FinanceStore.shared.requestAuthorization() == .authorized {
                    await updateView()
                }
                
                // Enable background delivery for the extension.
                FinanceStore.shared.enableBackgroundDelivery(for: [.transactions], frequency: .hourly)
            } catch {
                print("Error getting authorization: \(error)")
            }
        }
        .refreshable {
            await updateView()
        }
    }
    
    var formattedTotal: String {
        return weeklySpendingTotal.formatCompactCurrency()
    }
    
    func updateView() async {
        await updateTransactions()
        await updateWeeklySpending()
    }
    
    // Fetch transactions from the finance store and map them to the view model.
    func updateTransactions() async {
        do {
            transactions = try await FinanceUtilities.fetchLastWeekOfTransactions().map(
                TransactionModel.init
            )
        } catch {
            print("Error fetching transactions: \(error)")
        }
    }
    
    // Calculate the weekly spending and save it to storage.
    func updateWeeklySpending() async {
        do {
            let weeklySpending = try await FinanceUtilities.calculateWeeklySpendingTotal()
            weeklySpendingTotal = weeklySpending
            
            storage.setWeeklySpending(weeklySpending)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Unable to calculate weekly spending: \(error)")
        }
    }
}

struct TransactionRow: View {
    let transaction: TransactionModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text("\(transaction.description)")
                        .fontWeight(.medium)
                    Text("\(transaction.date.formatCompactDate)")
                        .font(.footnote)
                        .foregroundStyle(.gray)
                }
                Spacer(minLength: 32)
                Text("\(transaction.amount.formatCurrency(for: transaction.currency))")
            }
        }
    }
}

// Mapping FinanceKit transactions to a view model makes it easier to perform previews and testing.
struct TransactionModel: Identifiable {
    var id: UUID
    var description: String
    var amount: Decimal
    var currency: String
    var date: Date
    
    init(id: UUID, description: String, amount: Decimal, currency: String, date: Date) {
        self.id = id
        self.description = description
        self.amount = amount
        self.currency = currency
        self.date = date
    }
    
    init(transaction: FinanceKit.Transaction) {
        id = transaction.id
        description = transaction.transactionDescription
        amount = transaction.transactionAmount.amount
        currency = transaction.transactionAmount.currencyCode
        date = transaction.transactionDate
    }
}

#Preview {
    ContentView(
        weeklySpendingTotal: 400,
        transactions: [
            TransactionModel(
                id: UUID(),
                description: "Sample Merchant",
                amount: 6.99,
                currency: "GBP",
                date: .now
            ),
            TransactionModel(
                id: UUID(),
                description: "Another Merchant",
                amount: 200,
                currency: "GBP",
                date: .now
            )
        ]
    )
}
