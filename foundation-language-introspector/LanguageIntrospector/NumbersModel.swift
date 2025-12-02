/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for numbers.
*/

import SwiftUI

@MainActor
@Observable class NumbersModel {
    var formatter: NumberFormatter
    var numberStyle: NumberFormatter.Style { didSet { updateFormatter() } }
    var minimumFractionDigits: Int { didSet { updateFormatter() } }
    var maximumFractionDigits: Int { didSet { updateFormatter() } }
    var minimumIntegerDigits: Int { didSet { updateFormatter() } }
    var maximumIntegerDigits: Int { didSet { updateFormatter() } }
    var roundingMode: NumberFormatter.RoundingMode { didSet { updateFormatter() } }
    
    var localizedNumber: String {
        string(from: 32.745)
    }
    
    init() {
        self.formatter = NumberFormatter()
        self.numberStyle = .decimal
        self.minimumFractionDigits = 0
        self.maximumFractionDigits = 2
        self.minimumIntegerDigits = 1
        self.maximumIntegerDigits = 42
        self.roundingMode = NumberFormatter.RoundingMode.halfEven
        self.updateFormatter()
    }
    
    func string(from number: NSNumber) -> String {
        return formatter.string(from: number) ?? ""
    }
    
    private func updateFormatter() {
        formatter.numberStyle = numberStyle
        formatter.minimumFractionDigits = minimumFractionDigits
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.minimumIntegerDigits = minimumIntegerDigits
        formatter.maximumIntegerDigits = maximumIntegerDigits
        formatter.roundingMode = roundingMode
    }
}
