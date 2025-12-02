/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A file of utility methods for formatting numeric values in a way that's appropiate for frequently updating labels.
*/

import UIKit

protocol DisplayFormat {
    
    /// A string with a fixed width format that's appropiate for use in a UI with frequently updating values.
    var valueFormattedForDisplay: String? { get }
}

private let vectorFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.allowsFloats = true
    formatter.minimumFractionDigits = 3
    formatter.maximumFractionDigits = 3
    formatter.positivePrefix = "+"
    
    return formatter
}()

extension CGVector: DisplayFormat {
    
    var valueFormattedForDisplay: String? {
        let vectorAsNumbers = (dx: NSNumber(value: Double(dx)), dy: NSNumber(value: Double(dy)))
        
        // Using a custom formatter instead of `NSCoder.string(for:)` so there's a consistent amount of fraction digits.
        // Without this, a `UILabel` can be hard to read when the values update frequently because the label resizes
        // with a changing number of fractional digits.
        guard let xLabel = vectorFormatter.string(from: vectorAsNumbers.dx),
            let yLabel = vectorFormatter.string(from: vectorAsNumbers.dy)
        else { return nil }
        
        return "\(xLabel), \(yLabel)"
    }
}

private let pointFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.allowsFloats = true
    formatter.minimumFractionDigits = 1
    formatter.maximumFractionDigits = 1
    
    return formatter
}()

extension CGPoint: DisplayFormat {
    var valueFormattedForDisplay: String? {
        let coordAsNumbers = (x: NSNumber(value: Double(x)), y: NSNumber(value: Double(y)))
        
        // Using a custom formatter instead of `NSCoder.string(for:)` so there's a consistent amount of fraction digits.
        // Without this, a `UILabel` can be hard to read when the values update frequently because the label resizes
        // with a changing number of fractional digits.
        guard let xLabel = pointFormatter.string(from: coordAsNumbers.x),
            let yLabel = pointFormatter.string(from: coordAsNumbers.y)
            else { return nil }
        
        return "\(xLabel), \(yLabel)"
    }
}

private let valueFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.allowsFloats = true
    formatter.minimumFractionDigits = 3
    formatter.maximumFractionDigits = 3
    formatter.minimumIntegerDigits = 1
    formatter.positivePrefix = "+"
    
    return formatter
}()

extension CGFloat: DisplayFormat {
    var valueFormattedForDisplay: String? {
        let value = NSNumber(value: Double(self))
        return valueFormatter.string(from: value)
    }
}
