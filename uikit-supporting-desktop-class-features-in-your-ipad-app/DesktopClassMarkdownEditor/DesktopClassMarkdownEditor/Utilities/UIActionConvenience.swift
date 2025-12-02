/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience initializers for actions.
*/

import UIKit

extension UIAction {
    
    /// Convenience initializer for a "toggle" `UIAction`.
    convenience init<T>(_ title: String, image: UIImage? = nil, target: T, keyPath: ReferenceWritableKeyPath<T, Bool>) {
        self.init(title: title, image: image, state: target[keyPath: keyPath] ? .on : .off) { _ in
            target[keyPath: keyPath].toggle()
        }
    }
    
    /// Convenience initializer for a Double "setter" `UIAction`.
    convenience init<T>(_ title: String, image: UIImage? = nil, target: T, keyPath: ReferenceWritableKeyPath<T, Double>, value: Double) {
        self.init(title: title, image: image) { _ in
            target[keyPath: keyPath] = value
        }
    }
}
