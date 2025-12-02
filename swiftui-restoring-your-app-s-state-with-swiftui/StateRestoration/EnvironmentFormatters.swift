/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Shared number formatters as environment variables used in this sample app.
*/

import SwiftUI

// MARK: - CurrencyFormatter

private struct CurrencyFormatterKey: EnvironmentKey {
    static var defaultValue: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .currency
        return formatter
    }()
}

// MARK: - NumberFormatter

private struct NumberFormatterKey: EnvironmentKey {
    static var defaultValue = NumberFormatter()
}

extension EnvironmentValues {
    var currencyFormatter: NumberFormatter {
        get { self[CurrencyFormatterKey.self] }
        set { self[CurrencyFormatterKey.self] = newValue }
    }
    
    var numberFormatter: NumberFormatter {
        get { self[NumberFormatterKey.self] }
        set { self[NumberFormatterKey.self] = newValue }
    }
}
