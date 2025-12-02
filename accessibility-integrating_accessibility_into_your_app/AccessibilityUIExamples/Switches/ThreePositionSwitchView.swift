/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An example demonstrating making an accessible, custom three-position switch.
*/

import Cocoa

/*
 IMPORTANT: This is not a template for developing a custom switch.
 This sample is intended to demonstrate how to add accessibility to
 existing custom controls that are not implemented using the preferred methods.
 For information on how to create custom controls please visit:
 https://developer.apple.com/documentation/appkit/nscontrol
*/

class ThreePositionSwitchView: NSControl {
    
    private static let ThreePositionSwitchHandleWidth = CGFloat(45.0)
    
    enum SwitchPosition: Int {
        case left
        case center
        case right
    }
    
    // MARK: - Internals
    
    private var dragTrackingStartLocation = NSPoint()
    private var dragTrackingCurrentLocation = NSPoint()
    var position = SwitchPosition.left.rawValue
    var tracking = false
    
    // MARK: - Drawing

    override func draw(_ dirtyRect: NSRect) {
        // Draw the switch background.
        let wellBackgroundColor = NSColor.systemGray
        wellBackgroundColor.setFill()
        bounds.fill()

        // Draw the switch handle.
        var imageRect = NSRect()
        let origin = handleRect().origin
        imageRect.origin = origin
        imageRect.size.height = bounds.height
        imageRect.size.width = ThreePositionSwitchView.ThreePositionSwitchHandleWidth
        
        let switchHandleColor =
            //dragTrackingStartLocation.x < 0 && dragTrackingStartLocation.y < 0 ? NSColor.systemTeal : NSColor.systemPurple
            tracking ? NSColor.systemPurple : NSColor.systemTeal
        switchHandleColor.setFill()
        imageRect.fill()
    }

    private func handleRect() -> NSRect {
        var originX: CGFloat
        
        switch position {
        case SwitchPosition.center.rawValue:
            originX = CGFloat(bounds.size.width / 2.0) - (ThreePositionSwitchView.ThreePositionSwitchHandleWidth / 2.0)
        case SwitchPosition.right.rawValue:
            originX = CGFloat(bounds.size.width) - ThreePositionSwitchView.ThreePositionSwitchHandleWidth
        default:
            originX = 0
        }
        
        // Offset by current drag distance.
        originX -= (dragTrackingStartLocation.x - dragTrackingCurrentLocation.x)
        
        // Clamp to view bounds.
        originX = CGFloat(min(max(0, originX), bounds.size.width - ThreePositionSwitchView.ThreePositionSwitchHandleWidth))
        
        return NSRect(x: originX,
                      y: 0,
                      width: ThreePositionSwitchView.ThreePositionSwitchHandleWidth,
                      height: bounds.size.height)
    }
    
    // MARK: - Handle Movement
    
    private func snapHandleToClosestPosition() {
        let oneThirdWidth = bounds.size.width / 3.0
        
        var desiredPosition = 0
        
        let xPos = handleRect().midX
        if xPos < (bounds.origin.x + oneThirdWidth) {
            desiredPosition = SwitchPosition.left.rawValue
        } else if xPos > (bounds.origin.x + (oneThirdWidth * 2.0)) {
            desiredPosition = SwitchPosition.right.rawValue
        } else {
            desiredPosition = SwitchPosition.center.rawValue
        }
        
        if desiredPosition != position {
            position = desiredPosition
            
            // Call our action method in the owning view controller.
            NSApp.sendAction(action!, to: target, from: self)
        }
    }
    
    private func moveHandleToNextPositionRight(rightDirection: Bool, shouldWrap: Bool) {
        var nextPosition = 0
        
        switch position {
        case SwitchPosition.left.rawValue:
            if rightDirection {
                nextPosition = SwitchPosition.center.rawValue
            } else {
                nextPosition = shouldWrap ? SwitchPosition.right.rawValue : SwitchPosition.left.rawValue
            }
        case SwitchPosition.center.rawValue:
            nextPosition = rightDirection ? SwitchPosition.right.rawValue : SwitchPosition.left.rawValue
        case SwitchPosition.right.rawValue:
            if rightDirection {
                nextPosition = shouldWrap ? SwitchPosition.left.rawValue : SwitchPosition.right.rawValue
            } else {
                nextPosition = SwitchPosition.center.rawValue
            }
        default: break
        }
        
        if nextPosition != position {
            position = nextPosition
            
            // Call our action method in the owning view controller.
            NSApp.sendAction(action!, to: target, from: self)
            display()
        }
    }

    private func moveHandleToPreviousPositionWrapAround(shouldWrap: Bool) {
        moveHandleToNextPositionRight(rightDirection: false, shouldWrap: shouldWrap)
    }
    
    private func moveHandleToNextPositionWrapAround(shouldWrap: Bool) {
        moveHandleToNextPositionRight(rightDirection: true, shouldWrap: shouldWrap)
    }

    // MARK: - Mouse events

    private func handleMouseDrag(event: NSEvent) {
        var currentEvent = event
        let eventMask: NSEvent.EventTypeMask = [NSEvent.EventTypeMask.leftMouseUp, NSEvent.EventTypeMask.leftMouseDragged]
        let untilDate = NSDate.distantFuture

        tracking = true
        repeat {
            let mousePoint = convert(currentEvent.locationInWindow, from: nil)
            switch currentEvent.type {
            case NSEvent.EventType.leftMouseDown, NSEvent.EventType.leftMouseDragged:
                dragTrackingCurrentLocation = mousePoint
                currentEvent = (window?.nextEvent(matching: eventMask,
                                                  until: untilDate,
                                                  inMode: RunLoop.Mode.eventTracking,
                                                  dequeue: true))!
            default:
                tracking = false
            }
            display()
        }
        while tracking
        
        snapHandleToClosestPosition()
        
        // Reset our tracking states.
        dragTrackingCurrentLocation = NSPoint(x: -1, y: -1)
        dragTrackingStartLocation = NSPoint(x: -1, y: -1)
        
        display()
    }
    
    override func mouseDown(with event: NSEvent) {
        // If we are not enabled or can't become the first responder, don't do anything.
        guard isEnabled || (window?.makeFirstResponder(self))! else { return }
        
        // Determine the location, in our local coordinate system, where the user clicked.
        let location = convert(event.locationInWindow, from: nil)
        
        let pointInKnob = handleRect().contains(location)
        if pointInKnob {
            // When we receive a mouse down event, we reset the dragTrackingLocation.
            dragTrackingStartLocation = location
            handleMouseDrag(event: event)
        } else {
            // Treat clicks outside handle bounds as increment/decrement actions.
            let moveRight = location.x > handleRect().origin.x
            moveHandleToNextPositionRight(rightDirection: moveRight, shouldWrap: false)
        }
    }

    // MARK: - Keyboard Events
    
    // Allow keyDown, moveLeft, moveRight to be called.
    override var acceptsFirstResponder: Bool { return true }
    
    override func keyDown(with event: NSEvent) {
        if event.characters == " " {
            moveHandleToNextPositionWrapAround(shouldWrap: true)
        } else {
            // Arrow keys are associated with the numeric keypad.
            if event.modifierFlags.contains(.numericPad) {
                interpretKeyEvents([event])
            } else {
                super.keyDown(with: event)
            }
        }
    }
    
    override func moveLeft(_ sender: Any?) {
        moveHandleToPreviousPositionWrapAround(shouldWrap: false)
    }
    
    override func moveRight(_ sender: Any?) {
        moveHandleToNextPositionWrapAround(shouldWrap: false)
    }

}

// MARK: -

extension ThreePositionSwitchView {
    // MARK: Accessibility

    override func accessibilityValue() -> Any? {
        var returnValue = ""
        
        switch position {
        case SwitchPosition.center.rawValue:
            returnValue = NSLocalizedString("on", comment: "accessibility value for the state of ON for the switch")
        case SwitchPosition.right.rawValue:
            returnValue = NSLocalizedString("auto", comment: "accessibility value for the state of AUTO for the switch")
        default:
            returnValue = NSLocalizedString("off", comment: "accessibility value for the state of OFF for the switch")
        }
        
        return returnValue
    }
    
    override func accessibilityLabel() -> String? {
        return NSLocalizedString("Switch", comment: "accessibility label of the three position switch")
    }
    
    override func accessibilityHelp() -> String {
        return NSLocalizedString("A three position switch with off, on, and auto options.",
                                 comment: "accessibility help for the three position switch")
    }
    
    override func accessibilityPerformPress() -> Bool {
        // User did control-option-space keyboard shortcut.
        moveHandleToNextPositionWrapAround(shouldWrap: true)
        return true
    }
    
    // MARK: NSAccessibilitySwitch
    
    override func accessibilityPerformIncrement() -> Bool {
        moveHandleToNextPositionWrapAround(shouldWrap: false)
        return true
    }
    
    override func accessibilityPerformDecrement() -> Bool {
        moveHandleToPreviousPositionWrapAround(shouldWrap: false)
        return true
    }
    
}

