/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utilities to add gesture recognizers.
*/

import UIKit

extension UIViewController {

    /// Creates a `UITapGestureRecognizer` and adds it to the `UIView` with the specified allowed
    /// press types. Sets the target and action, if specified.
    ///
    /// - Parameter view: The `UIView` to add the tap gesture recognizer.
    /// - Parameter allowedPressTypes: The allowed press types for the tap gesture recognizer.
    /// - Parameter target: The target object for the tap gesture recognizer.
    /// - Parameter action: The action for the tap gesture recognizer.
    func addTapGestureRecognizer(toView view: UIView, withAllowedPressTypes allowedPressTypes: [UIPress.PressType], forTarget target: Any?, andAction action: Selector?) {
        let tapGesture = UITapGestureRecognizer(target: target, action: action)
        add(gestureRecognizer: tapGesture, toView: view, withAllowedPressTypes: allowedPressTypes)
    }

    /// Creates a `UILongPressGestureRecognizer` and adds it to the `UIView` with the specified
    /// allowed press types. Sets the target and action, if specified.
    ///
    /// - Parameter view: The `UIView` to add the long-press gesture recognizer.
    /// - Parameter allowedPressTypes: The allowed press types for the long-press gesture
    ///   recognizer.
    /// - Parameter target: The target object for the long-press gesture recognizer.
    /// - Parameter action: The action for the long-press gesture recognizer.
    func addLongPressGestureRecognizer(toView view: UIView, forTarget target: Any?, withAllowedPressTypes allowedPressTypes: [UIPress.PressType], andAction action: Selector?) {
        let longPressGesture = UILongPressGestureRecognizer(target: target, action: action)
        add(gestureRecognizer: longPressGesture, toView: view, withAllowedPressTypes: allowedPressTypes)
    }

    /// Creates a `UISwipeGestureRecognizer` and adds it to the `UIView` with the specified
    /// direction. Sets the target and action, if specified.
    ///
    /// - Parameter view: The `UIView` to add the swipe gesture recognizer.
    /// - Parameter direction: The direction for the swipe gesture recognizer.
    /// - Parameter target: The target object for the swipe gesture recognizer.
    /// - Parameter action: The action for the swipe gesture recognizer.
    func addSwipeGestureRecognizer(toView view: UIView, withDirection direction: UISwipeGestureRecognizer.Direction, forTarget target: Any?, andAction action: Selector?) {
        let swipeGesture = UISwipeGestureRecognizer(target: target, action: action)
        swipeGesture.direction = direction
        view.addGestureRecognizer(swipeGesture)
    }

    /// Adds a `UIGestureRecognizer` to the `UIView` with the specified allowed press types.
    ///
    /// - Parameter gestureRecognizer: The gesture recognizer to add to the view.
    /// - Parameter allowedPressTypes: The press types the gesture recognizer allows.
    private func add(gestureRecognizer: UIGestureRecognizer, toView view: UIView, withAllowedPressTypes allowedPressTypes: [UIPress.PressType]) {
        gestureRecognizer.allowedPressTypes = allowedPressTypes.map { $0.rawValue as NSNumber }
        view.addGestureRecognizer(gestureRecognizer)
    }
}
