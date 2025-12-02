/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A convenience utility that formats numbers as currency.
*/

import Foundation

extension NumberFormatter {
    public static var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }
}
