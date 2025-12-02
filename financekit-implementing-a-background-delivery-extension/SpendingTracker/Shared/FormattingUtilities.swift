/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The functions for formatting currency and dates.
*/

import Foundation

extension Decimal {
    // Format this as the specified currency and round it at larger numbers.
    func formatCurrency(for currencyCode: String, locale: Locale = .autoupdatingCurrent, compact: Bool = false) -> String {
        // If the value is more than `10`, round to the nearest whole number for clarity.
        let shouldRound = self >= 10 && compact
        
        let currencyStyle = Decimal.FormatStyle.Currency(
            code: currencyCode,
            locale: locale
        )
        
        let formatStyle = if shouldRound {
            currencyStyle.precision(.fractionLength(0))
        } else {
            currencyStyle
        }
        
        return self.formatted(formatStyle)
    }
    
    // Use the currency from the locale to format this as a currency that rounds at larger numbers.
    func formatCompactCurrency(locale: Locale = .autoupdatingCurrent) -> String {
        // Fall back to noncurrency formatting if the current locale doesn't have a currency.
        guard let currencyCode = locale.currency?.identifier else {
            return self.formatted()
        }
        
        return formatCurrency(for: currencyCode, locale: locale, compact: true)
    }
}

extension Date {
    var formatCompactDate: String {
        // If it's today, show only the time; otherwise, show only the date.
        if Calendar.current.isDateInToday(self) {
            return self.formatted(date: .omitted, time: .shortened)
        } else {
            return self.formatted(date: .numeric, time: .omitted)
        }
    }
}
