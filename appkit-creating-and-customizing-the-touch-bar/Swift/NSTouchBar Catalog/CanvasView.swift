/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom NSView responsible for showing low-level touch events.
*/

import Cocoa

class CanvasView: NSView {
    
    // This is to keep the current tracking touch (figure).
    // NSTouchBar supports multiple touches, but since it has only 30-point height,
    // it is reasonable to only track one touch.
    var trackingTouchIdentity: AnyObject?
    
    // Marked as dynamic for this property to support KVO.
    @objc dynamic var trackingLocationString = ""
    
    // NSView by default doesn't accept first responder, so override this to allow it.
    override var acceptsFirstResponder: Bool { return true }
    
    override func touchesBegan(with event: NSEvent) {
        // trackingTouchIdentity != nil:
        // You're already tracking a touch, so ignore this new touch.
        if trackingTouchIdentity == nil {
            if let touch = event.touches(matching: .began, in: self).first, touch.type == .direct {
                trackingTouchIdentity = touch.identity
                let location = touch.location(in: self)
                trackingLocationString = String(format: NSLocalizedString("Began At", comment: ""), location.x)
            }
        }
        super.touchesBegan(with: event)
    }
    
    override func touchesMoved(with event: NSEvent) {
        if let trackingTouchIdentity = trackingTouchIdentity {
            let relevantTouches = event.touches(matching: .moved, in: self)
            let actualTouches = relevantTouches.filter({ $0.type == .direct && $0.identity.isEqual(trackingTouchIdentity) })
            if let trackingTouch = actualTouches.first {
                let location = trackingTouch.location(in: self)
                trackingLocationString = String(format: NSLocalizedString("Moved At", comment: ""), location.x)
            }
        }
        super.touchesMoved(with: event)
    }
    
    override func touchesEnded(with event: NSEvent) {
        if let trackingTouchIdentity = trackingTouchIdentity {
            let relevantTouches = event.touches(matching: .ended, in: self)
            let actualTouches = relevantTouches.filter({ $0.type == .direct && $0.identity.isEqual(trackingTouchIdentity) })
            if let trackingTouch = actualTouches.first {
                self.trackingTouchIdentity = nil
                let location = trackingTouch.location(in: self)
                trackingLocationString = String(format: NSLocalizedString("Ended At", comment: ""), location.x)
            }
        }
        super.touchesEnded(with: event)
    }
    
    override func touchesCancelled(with event: NSEvent) {
        if let trackingTouchIdentity = trackingTouchIdentity {
            let relevantTouches = event.touches(matching: .cancelled, in: self)
            let actualTouches = relevantTouches.filter({ $0.type == .direct && $0.identity.isEqual(trackingTouchIdentity) })
            if let trackingTouch = actualTouches.first {
                self.trackingTouchIdentity = nil
                let location = trackingTouch.location(in: self)
                trackingLocationString = String(format: NSLocalizedString("Cancelled At", comment: ""), location.x)
                
                // The system is cancelling the touch, so roll back to the status before touchBegan.
                //...
            }
        }
        super.touchesCancelled(with: event)
    }
    
}

