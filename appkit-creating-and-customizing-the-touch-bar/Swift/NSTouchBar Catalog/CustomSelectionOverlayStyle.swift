/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom selection overlay view for NSScrubber.
*/

import Cocoa

private class CustomSelectionOverlayView: NSScrubberSelectionView {
    override func draw(_ dirtyRect: NSRect) {
        // Draw as an overlay: with a rounded rect, green.
        NSColor.systemGreen.set()
        NSBezierPath(roundedRect: dirtyRect.insetBy(dx: 4.0, dy: 4.0), xRadius: 6, yRadius: 6).fill()
    }
    
}

// MARK: -

class CustomSelectionOverlayStyle: NSScrubberSelectionStyle {
    override func makeSelectionView () -> NSScrubberSelectionView? {
        return CustomSelectionOverlayView()
    }
    
}

