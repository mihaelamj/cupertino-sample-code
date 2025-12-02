/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The split view for showing the document preview alongside the document content.
*/

import UIKit

class SplitViewResizeGesture: UIGestureRecognizer {
    var initialLocationInWindow = CGPoint(x: CGFloat.leastNormalMagnitude, y: CGFloat.leastNormalMagnitude)
    
    func currentTranslation() -> CGPoint {
        if let theView = view {
            let currentLocationInWindow = location(in: theView.window)
            return CGPoint(x: currentLocationInWindow.x - initialLocationInWindow.x,
                           y: currentLocationInWindow.y - initialLocationInWindow.y)
        }
        
        return .zero
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        initialLocationInWindow = location(in: view!.window)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        var nextState: State
        
        switch state {
        case .possible:
            nextState = .began
        case .began:
            nextState = .changed
        default:
            nextState = state
        }
        
        state = nextState
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        
        if state == .began || state == .changed {
            state = .ended
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        
        if state == .began || state == .changed {
            state = .cancelled
        }
    }
}

class SplitView: UIView, UIPointerInteractionDelegate {
    let resizeKnob = ResizeKnob()
    let previewVisibilityBarButton = UIBarButtonItem()

    var splitSize = 0.0 {
        didSet {
            updateSplit()
        }
    }
    
    override var bounds: CGRect {
        didSet {
            layoutSplitView(interactive: false)
        }
    }
    
    override var frame: CGRect {
        didSet {
            layoutSplitView(interactive: false)
        }
    }
    
    var panels = [UIView]() {
        didSet {
            assert(panels.count <= 2, "SplitView only supports up to 2 panels!")
            
            for panel in panels {
                addSubview(panel)
            }
            
            if panels.isEmpty == false {
                previewVisibilityBarButton.primaryAction = UIAction(title: "Show Preview", image: UIImage(systemName: "eye")) { [unowned self] _ in
                    toggleSplit()
                }
                
                updateVisibilityMenu(allowsSplit: allowsSplit)
                
                resizeKnob.addGestureRecognizer(SplitViewResizeGesture(target: self, action: #selector(handleResizeGesture)))
                resizeKnob.outer.backgroundColor = backgroundColor
                addSubview(resizeKnob)
            
                if allowsSplit {
                    UIView.performWithoutAnimation {
                        toggleSplit()
                    }
                }
            }
        }
    }

    func layoutSplitView(_ secondPanelVisibilityFraction: CGFloat? = nil, interactive: Bool) {
        let splitPanels = traitCollection.layoutDirection == .leftToRight ? panels : panels.reversed()

        if splitPanels.isEmpty { return }
        
        var splitFraction = 0.0
        
        if secondPanelVisibilityFraction != nil {
            splitFraction = secondPanelVisibilityFraction!
        } else {
            splitFraction = splitPoint
        }
        
        // If the preview is going to become visible, make sure it's in the view hierarchy
        if splitFraction > 0 && splitPanels[1].window == nil {
            insertSubview(splitPanels[1], aboveSubview: splitPanels[0])
        }
            
        let split = (1.0 - splitFraction) * bounds.width
        let rects = bounds.divided(atDistance: split, from: .minXEdge)

        var leftPanelFrame = rects.slice
        leftPanelFrame.size.width = max(bounds.midX, leftPanelFrame.width)
        leftPanelFrame.origin.x = rects.remainder.minX - leftPanelFrame.width
        splitPanels[0].frame = leftPanelFrame

        var rightPanelFrame = rects.remainder
        rightPanelFrame.size.width = max(bounds.midX, rightPanelFrame.width)
        splitPanels[1].frame = rightPanelFrame
        
        // Clamp the resize knob's x position so it always remains completely visible within the bounds of the view.
        let resizeKnobX = max(bounds.minX + resizeKnob.bounds.midX + 1, min(split, bounds.maxX - resizeKnob.bounds.midX - 1))
        resizeKnob.center = CGPoint(x: resizeKnobX, y: bounds.midY)
    }
    
    // MARK: Gesture Handling

    @objc
    func handleResizeGesture(_ gesture: SplitViewResizeGesture) {
        let translation = gesture.currentTranslation()
        var startPoint = splitSize
        if traitCollection.layoutDirection == .rightToLeft {
            startPoint = 1.0 - startPoint
        }

        let targetSplitSize = (startPoint - translation.x / bounds.width)

        switch gesture.state {
        case .began, .changed:
            layoutSplitView(targetSplitSize, interactive: true)
        default:
            let maxVisiblePanels = allowsSplit ? 2.0 : 1.0
            let adjustedSplitSize = round(targetSplitSize * maxVisiblePanels) / maxVisiblePanels
            
            if traitCollection.layoutDirection == .leftToRight {
                splitSize = adjustedSplitSize
            } else {
                splitSize = 1.0 - adjustedSplitSize
            }

            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0) {
                self.layoutSplitView(interactive: false)
            }
        }
    }
    
    var splitPoint: CGFloat {
        if traitCollection.layoutDirection == .leftToRight {
            return splitSize
        } else {
            return 1.0 - splitSize
        }
    }
    
    var allowsSplit: Bool {
        traitCollection.horizontalSizeClass != .compact
    }
    
    func updateSplit() {
        var duration = 0.0
        
        if splitSize > 0 {
            previewVisibilityBarButton.image = UIImage(systemName: "eye.slash")
            previewVisibilityBarButton.title = "Hide Preview"
            duration = 0.6
        } else {
            previewVisibilityBarButton.image = UIImage(systemName: "eye")
            previewVisibilityBarButton.title = "Show Preview"
            duration = 0.35
        }
        
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0) {
            self.layoutSplitView(interactive: false)
        } completion: { _ in
            if self.splitSize == 0.0 {
                self.panels.last?.removeFromSuperview()
            }
        }
    }
    
    func toggleSplit() {
        if splitSize > 0.0 {
            splitSize = 0.0
        } else {
            splitSize = allowsSplit ? 0.5 : 1.0
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateVisibilityMenu(allowsSplit: allowsSplit)
    }
    
    private func updateVisibilityMenu(allowsSplit: Bool) {
        if allowsSplit {
            let splitSizeMenu = UIMenu(preferredElementSize: .medium, children: [
                UIAction("Full", image: UIImage(systemName: "rectangle.center.inset.filled"), target: self, keyPath: \.splitSize, value: 1.0),
                UIAction("Half", image: UIImage(systemName: "rectangle.trailinghalf.inset.filled"), target: self, keyPath: \.splitSize, value: 0.5),
                UIAction("Hidden", image: UIImage(systemName: "eye.slash"), target: self, keyPath: \.splitSize, value: 0.0)
            ])
            previewVisibilityBarButton.menu = splitSizeMenu
        } else {
            previewVisibilityBarButton.menu = nil
        }
    }
}
