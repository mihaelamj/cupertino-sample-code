/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Small extensions to simplify view handling in the demo app.
*/

#if os(iOS)
import UIKit
typealias View = UIView
#elseif os(macOS)
import AppKit
typealias View = NSView
#endif

public extension View {
    func pinToSuperview() {
        guard let superview = superview else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview.topAnchor),
            leadingAnchor.constraint(equalTo: superview.leadingAnchor),
            bottomAnchor.constraint(equalTo: superview.bottomAnchor),
            trailingAnchor.constraint(equalTo: superview.trailingAnchor)
        ])
    }
}
