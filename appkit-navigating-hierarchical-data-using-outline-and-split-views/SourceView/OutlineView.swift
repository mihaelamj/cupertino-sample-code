/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The subclass of NSOutlineView for contextual menu support.
*/

import Cocoa

class OutlineView: NSOutlineView {
    
	weak var customMenuDelegate: CustomMenuDelegate?
    
    var contextualRect = NSRect()
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        if !contextualRect.isEmpty {
            // Draw the highlight.
            let rectPath = NSBezierPath(rect: contextualRect)
            let fillColor = NSColor.keyboardFocusIndicatorColor
            fillColor.set()
            rectPath.stroke()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        if !contextualRect.isEmpty {
            // Clear the highlight if the user clicks away from the menu.
            contextualRect = NSRect()
            setNeedsDisplay(contextualRect)
        }
    }
    
    // The view is asking for a contextual menu representation.
    override func menu(for event: NSEvent) -> NSMenu? {
        // Reset the contextual menu frame for next use.
        contextualRect = NSRect()
 
        let targetRow = row(at: convert(event.locationInWindow, from: nil))
        if targetRow != -1 {
            contextualRect = frameOfCell(atColumn: 0, row: targetRow)
            
            let selectedRowFrame = frameOfCell(atColumn: 0, row: selectedRow)
            if contextualRect.intersects(selectedRowFrame) {
                contextualRect = NSRect()
            }
        }
        
        setNeedsDisplay(contextualRect) // Draw the highlight rectangle if necessary.
        
        if contextualRect.isEmpty {
            // The contextual menu operates on the current selection.
            // This calls our contextual menu delegate (OutlineViewController).
            return customMenuDelegate?.outlineViewMenuForRows(self, rows: selectedRowIndexes)
        } else {
            // The contexual menu operates on the target row that the user Command-clicked outside of the selection.
            let selectedRowIndexes = IndexSet([targetRow])
            // This calls our contextual menu delegate (OutlineViewController).
            return customMenuDelegate?.outlineViewMenuForRows(self, rows: selectedRowIndexes)
    	}
    }
    
    override func didCloseMenu(_ menu: NSMenu, with event: NSEvent?) {
        super.didCloseMenu(menu, with: event)
        
        if !contextualRect.isEmpty {
            // Clear the highlight when the menu closes.
            contextualRect = NSRect()
            setNeedsDisplay(bounds)
        }
    }
    
}
