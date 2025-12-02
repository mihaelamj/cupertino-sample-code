/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Pointer style provider for UIButtons.
*/

import UIKit

extension ViewController {
    enum ButtonPointerEffectKind: Int {
        case pointer = 1
        case highlight
        case lift
        case hover
        case custom
    }
    
    // This is called when the pointer moves over the button.
    func buttonProvider(button: UIButton, pointerEffect: UIPointerEffect, pointerShape: UIPointerShape) -> UIPointerStyle? {
        var buttonPointerStyle: UIPointerStyle? = nil
        
        // Use the pointer effect's preview that's passed in.
        let targetedPreview = pointerEffect.preview
        
        // Use the button's view tag to determine which pointer effect to use.
        let buttonTag = ViewController.ButtonPointerEffectKind(rawValue: button.tag)
        switch buttonTag {
        case .pointer:
            /** UIPointerEffect.automatic attempts to determine the appropriate effect for the given preview automatically.
                The pointer effect has an automatic nature which adapts to the aspects of the button (background color, corner radius, size)
            */
            let buttonPointerEffect = UIPointerEffect.automatic(targetedPreview)
            buttonPointerStyle = UIPointerStyle(effect: buttonPointerEffect, shape: pointerShape)
            
        case .highlight:
            // Pointer slides under the given view and morphs into the view's shape.
            let buttonHighlightPointerEffect = UIPointerEffect.highlight(targetedPreview)
            buttonPointerStyle = UIPointerStyle(effect: buttonHighlightPointerEffect, shape: pointerShape)
            
        case .lift:
            /** Pointer slides under the given view and disappears as the view scales up and gains a shadow.
                Make the pointer shape’s bounds match the view’s frame so the highlight extends to the edges.
            */
            let buttonLiftPointerEffect = UIPointerEffect.lift(targetedPreview)
            let customPointerShape = UIPointerShape.path(UIBezierPath(roundedRect: button.bounds, cornerRadius: 6.0))
            buttonPointerStyle = UIPointerStyle(effect: buttonLiftPointerEffect, shape: customPointerShape)
            
        case .hover:
            /** Pointer retains the system shape while over the given view.
                Visual changes applied to the view are dictated by the effect's properties.
            */
            let buttonHoverPointerEffect =
                UIPointerEffect.hover(targetedPreview, preferredTintMode: .none, prefersShadow: true)
            buttonPointerStyle = UIPointerStyle(effect: buttonHoverPointerEffect, shape: nil)

        case .custom:
            /** Hover pointer with a custom triangle pointer shape.
                Override the default UITargetedPreview with our own, make the visible path outset a little larger.
            */
            let parameters = UIPreviewParameters()
            parameters.visiblePath = UIBezierPath(rect: button.bounds.insetBy(dx: -15.0, dy: -15.0))
            let newTargetedPreview = UITargetedPreview(view: button, parameters: parameters)

            let buttonPointerEffect =
                UIPointerEffect.hover(newTargetedPreview, preferredTintMode: .overlay, prefersShadow: false, prefersScaledContent: false)
            
            let customPointerShape = UIPointerShape.path(trianglePointerShape())
            buttonPointerStyle = UIPointerStyle(effect: buttonPointerEffect, shape: customPointerShape)
           
        default: break
        }

        return buttonPointerStyle
    }
    
}
