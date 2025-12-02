/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A format style that formats a double precision value as an integer.
*/
import Foundation

/// `ProductivityChart` uses this type to format the values on the y-axis.
struct IntegerFormatStyle: FormatStyle {
    func format(_ value: Double) -> String {
        " \(Int(value))"
    }
}
