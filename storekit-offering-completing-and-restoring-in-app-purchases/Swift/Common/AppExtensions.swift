/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience class extensions.
*/

#if os (macOS)
import Cocoa
#elseif os (iOS)
import UIKit
#endif
import Foundation
import StoreKit

// MARK: - DateFormatter

extension DateFormatter {
    /// - returns: A string representation of date using the short time and the date style.
    class func short(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
    
    /// - returns: A string representation of date using the long time and the date style.
    class func long(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .long
        return dateFormatter.string(from: date)
    }
}

// MARK: - Section

extension Section {
    /// - returns: A Section object matching the specified name in the data array.
    static func parse(_ data: [Section], for type: SectionType) -> Section? {
        let section = (data.filter({ (item: Section) in item.type == type }))
        return (!section.isEmpty) ? section.first : nil
    }
}

// MARK: - SKProduct

extension SKProduct {
    /// - returns: The cost of the product formatted in the local currency.
    var regularPrice: String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = self.priceLocale
        return formatter.string(from: self.price)
    }
}

// MARK: - DiscloseView

#if os (macOS)
extension NSView: DiscloseView {
    /// Show the view.
    func show() {
        self.isHidden = false
    }
    
    /// Hide the view.
    func hide() {
        self.isHidden = true
    }
}
#else
extension UIView: DiscloseView {
    /// Show the view.
    func show() {
        self.isHidden = false
    }
    
    /// Hide the view.
    func hide() {
        self.isHidden = true
    }
}

// MARK: - EnableItem

extension UIBarItem: EnableItem {
    /// Enable the bar item.
    func enable() {
        self.isEnabled = true
    }
    
    /// Disable the bar item.
    func disable() {
        self.isEnabled = false
    }
}
#endif

// MARK: - ProductIdentifiers

extension ProductIdentifiers {
    var isEmpty: String {
        return "\(name).\(fileExtension) is empty. \(Messages.updateResource)"
    }
    
    var wasNotFound: String {
        return "\(Messages.couldNotFind) \(name).\(fileExtension)."
    }
    
    /// - returns: An array with the product identifiers to query.
    var identifiers: [String]? {
        guard let path = Bundle.main.path(forResource: self.name, ofType: self.fileExtension) else { return nil }
        return NSArray(contentsOfFile: path) as? [String]
    }
}
