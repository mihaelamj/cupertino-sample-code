/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Methods and extensions for handling keyboard resign events.
*/

import SwiftUI

/// A view modifier that resigns the keyboard on a drag gesture.
struct ResignKeyboardOnDragGesture: ViewModifier {
    var gesture = DragGesture().onChanged { _ in
        TextEditingSupport.endEditing(force: true)
    }
    
    func body(content: Content) -> some View {
        content.gesture(gesture)
    }
}

// MARK: - Convenience extension on View to access above defined functionality

extension View {
    func endEditing(force: Bool) {
        TextEditingSupport.endEditing(force: force)
    }
    
    func resignKeyboardOnDragGesture() -> some View {
        return modifier(ResignKeyboardOnDragGesture())
    }
}

// MARK: - Convenience functions for making changes related to the first responder

private struct TextEditingSupport {
    static func endEditing(force: Bool) {
        keyWindow?.endEditing(force)
    }
    
    static var keyWindow: UIWindow? {
        let windowScenes = UIApplication.shared.connectedScenes.compactMap { scene in
            return (scene as? UIWindowScene)
        }
        return windowScenes.first?.keyWindow
    }
    
    static func firstSubview<ViewType: UIView>(in view: UIView, where predicate: (ViewType) -> Bool) -> ViewType? {
        var matchingSubview: ViewType?
        let subviews = view.subviews
        for subview in subviews {
            if let subviewOfMatchingType = subview as? ViewType {
                if predicate(subviewOfMatchingType) {
                    matchingSubview = subviewOfMatchingType
                }
            }
            if matchingSubview == nil {
                matchingSubview = firstSubview(in: subview, where: predicate)
            }
            if matchingSubview != nil {
                break
            }
        }
        return matchingSubview
    }
}
