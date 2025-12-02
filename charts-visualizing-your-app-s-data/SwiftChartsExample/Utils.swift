/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility views and functions.
*/

import SwiftUI

enum TimeRange {
    case last30Days
    case last12Months
}

struct TimeRangePicker: View {
    @Binding var value: TimeRange

    var body: some View {
        Picker(selection: $value.animation(.easeInOut), label: EmptyView()) {
            Text("30 Days").tag(TimeRange.last30Days)
            Text("12 Months").tag(TimeRange.last12Months)
        }
        .pickerStyle(.segmented)
    }
}

struct Transaction: Identifiable, Hashable {
    let id = UUID()
}

/// A few fake transactions for display.
let transactions = [
    Transaction(),
    Transaction(),
    Transaction(),
    Transaction(),
    Transaction(),
    Transaction(),
    Transaction(),
    Transaction()
]

struct TransactionsLink: View {
    var body: some View {
        NavigationLink("Show Transactions", value: transactions)
    }
}

struct TransactionsView: View {
    let transactions: [Transaction]

    var body: some View {
        List {
            ForEach(transactions) { _ in
                HStack { Text("Year Month Day"); Text("Style"); Spacer(); Text("123") }
            }
        }
        .redacted(reason: .placeholder)
        .navigationTitle("Transactions")
    }
}
