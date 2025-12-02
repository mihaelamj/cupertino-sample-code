/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom control using Gesture Recognizers and hit testing beyond its initial bounds.
*/

import UIKit

class RingControl: UIView {
    var selectedView: RingView!
    var previousView: RingView! // Last tool used.
    var tapRecognizer: UITapGestureRecognizer!
    var ringViews = [RingView]()
    
    var ringRadius: CGFloat {
        return bounds.width / 2.0
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func setupRings(itemCount: Int) {
        // Define some nice colors.
        let borderColorSelected = #colorLiteral(red: 0, green: 0.7445889711, blue: 1, alpha: 1).cgColor
        let borderColorNormal = UIColor.darkGray.cgColor
        let fillColorSelected = #colorLiteral(red: 0.6543883085, green: 0.8743371367, blue: 1, alpha: 1)
        let fillColorNormal = UIColor.white
        
        // We define generators to return closures which we use to define
        // the different states of our item ring views. Since we add those
        // to the view, they need to capture the view unowned to avoid a
        // retain cycle.
        let selectedGenerator = { (view: RingView) -> () -> Void in
            return { [unowned view] in
                view.layer.borderColor = borderColorSelected
                view.backgroundColor = fillColorSelected
            }
        }
        
        let normalGenerator = { (view: RingView) -> () -> Void in
            return { [unowned view] in
                view.layer.borderColor = borderColorNormal
                view.backgroundColor = fillColorNormal
            }
        }
        
        let startPosition = bounds.center
        let locationNormalGenerator = { (view: RingView) -> () -> Void in
            return { [unowned view] in
                view.center = startPosition
                if !view.selected {
                    view.alpha = 0.0
                }
            }
        }

        let locationFanGenerator = { (view: RingView, offset: CGVector) -> () -> Void in
            return { [unowned view] in
                view.center = startPosition + offset
                view.alpha = 1.0
            }
        }

        // tau is a full circle in radians
        let tau = CGFloat.pi * 2
        let absoluteRingSegment = tau / 4.0
        let requiredLengthPerRing = ringRadius * 2 + 5.0
        let totalRequiredCirlceSegment = requiredLengthPerRing * CGFloat(itemCount - 1)
        let fannedControlRadius = max(requiredLengthPerRing, totalRequiredCirlceSegment / absoluteRingSegment)
        let normalDistance = CGVector(dx: 0, dy: -1 * fannedControlRadius)
        
        let scale = UIScreen.main.scale

        // Setup our item views.
        for index in 0..<itemCount {
            let view = RingView(frame: self.bounds)
            view.stateClosures[.selected] = selectedGenerator(view)
            view.stateClosures[.normal] = normalGenerator(view)
            let transformToApply = CGAffineTransform(rotationAngle: CGFloat(index) / CGFloat(itemCount - 1) * (absoluteRingSegment))
            view.stateClosures[.locationFan] = locationFanGenerator(view, normalDistance.applying(transformToApply).rounding(toScale: scale))
            view.stateClosures[.locationOrigin] = locationNormalGenerator(view)
            self.addSubview(view)
            ringViews.append(view)

            let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
            view.addGestureRecognizer(tapRecognizer)
        }
    }

    func setupInitialSelectionState() {
        guard let selectedView = ringViews.first else { return }

        addSubview(selectedView)
        selectedView.selected = true
        self.selectedView = selectedView
        self.previousView = selectedView
        updateViews(animated: false)
    }
    
    // MARK: View interaction and animation
    
    @objc
    func tap(_ recognizer: UITapGestureRecognizer) {
        guard let view = recognizer.view as? RingView else { return }
            
        let fanState = view.fannedOut
        
        if fanState {
            select(view: view)
        } else {
            for view in ringViews {
                view.fannedOut = true
            }
        }
        
        self.updateViews(animated: true)
    }

    func cancelInteraction() {
        guard selectedView.fannedOut else { return }

        for view in ringViews {
            view.fannedOut = false
        }
        self.updateViews(animated: true)
    }
    
    func select(view: RingView) {
        for view in ringViews {
            if view.selected {
                view.selected = false
                view.selectionState?()
            }
            view.fannedOut = false
        }
        view.selected = true
        // Is the selected view changing?
        if selectedView !== view {
            // Yes, so remember it as the previous view.
            previousView = selectedView
        }
        selectedView = view
        view.actionClosure?()
    }
    
    func updateViews(animated: Bool) {
        // Order the selected view in front.
        self.addSubview(selectedView)
        
        var stateTransitions = [() -> Void]()
        for view in ringViews {
            if let state = view.selectionState {
                stateTransitions.append(state)
            }
            if let state = view.locationState {
                stateTransitions.append(state)
            }
        }
        
        let transition = {
            for transition in stateTransitions {
                transition()
            }
        }
        
        if animated {
            UIView.animate(withDuration: 0.25, animations: transition)
        } else {
            transition()
        }
    }
    
    // MARK: Hit testing
    
    // Hit test on our ring views regardless of our own bounds.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for view in self.subviews.reversed() {
            let localPoint = view.convert(point, from: self)
            if view.point(inside: localPoint, with: event) {
                return view
            }
        }
        // Don't hit-test ourself.
        return nil
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        for view in self.subviews.reversed() {
            if view.point(inside: view.convert(point, from: self), with: event) {
                return true
            }
        }
        return super.point(inside: point, with: event)
    }
    
}

// MARK: - Pencil interaction

extension RingControl {

    func switchToPreviousTool() {
        // If the tools aren't fanned out, fan out the
        // previous one to animate it from its fan location.
        if selectedView.fannedOut == false {
            previousView.fannedOut = true
            updateViews(animated: false)
        }

        select(view: previousView)
        updateViews(animated: true)
    }

}
