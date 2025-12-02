/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The resizing mechanism for adjusting the size of the split view.
*/

import UIKit

class ResizeKnob: UIView, UIPointerInteractionDelegate {
    let outer = UIView()
    let mid = UIView()
    let inner = UIView()
    let inset = 2.0
    let expandedDiameter = 55

    var hovered = false
    
    var hitRect: CGRect {
        bounds.inset(by: UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10))
    }
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: 12, height: 12))
        
        addSubview(outer)
        outer.layer.allowsEdgeAntialiasing = true
        outer.isUserInteractionEnabled = false
        
        addSubview(mid)
        mid.layer.allowsEdgeAntialiasing = true
        mid.layer.borderColor = UIColor.white.cgColor
        mid.layer.borderWidth = 14.0
        mid.isUserInteractionEnabled = false
        
        addSubview(inner)
        inner.layer.allowsEdgeAntialiasing = true
        inner.backgroundColor = .white
        inner.isUserInteractionEnabled = false
        
        addInteraction(UIPointerInteraction(delegate: self))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutHovered(hovered)
    }
    
    // MARK: UIPointerInteractionDelegate
    func pointerInteraction(
        _ interaction: UIPointerInteraction,
        regionFor request: UIPointerRegionRequest,
        defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        let region = UIPointerRegion(rect: hitRect)
        region.latchingAxes = .horizontal
        return region
    }
    
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        let preview = UITargetedPreview(view: inner)
        let style = UIPointerStyle(effect: .lift(preview))
        style.accessories = [ .arrow(.left), .arrow(.right) ]
        return style
    }
    
    func pointerInteraction(_ interaction: UIPointerInteraction, willEnter region: UIPointerRegion, animator: UIPointerInteractionAnimating) {
        animator.addAnimations { [unowned self] in
            hovered = true
            layoutHovered(hovered)
        }
    }
    
    func pointerInteraction(_ interaction: UIPointerInteraction, willExit region: UIPointerRegion, animator: UIPointerInteractionAnimating) {
        animator.addAnimations { [unowned self] in
            hovered = false
            layoutHovered(hovered)
        }
    }
    
    func layoutHovered(_ hovered: Bool) {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        outer.center = center
        mid.center = center
        inner.center = center

        if hovered {
            outer.bounds = CGRect(x: 0, y: 0, width: expandedDiameter, height: expandedDiameter)
            mid.bounds = outer.bounds.insetBy(dx: inset, dy: inset)
            inner.backgroundColor = .tintColor
        } else {
            outer.bounds = bounds
            mid.bounds = bounds.insetBy(dx: inset, dy: inset)
            inner.bounds = bounds.insetBy(dx: inset, dy: inset)
            inner.backgroundColor = .white
        }
        
        outer.layer.cornerRadius = outer.bounds.height / 2.0
        mid.layer.cornerRadius = mid.bounds.height / 2.0
        inner.layer.cornerRadius = inner.bounds.height / 2.0
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if hitRect.contains(point) {
            return self
        }
        
        return super.hitTest(point, with: event)
    }
}
