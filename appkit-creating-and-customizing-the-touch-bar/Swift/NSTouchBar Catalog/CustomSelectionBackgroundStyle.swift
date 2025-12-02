/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom selection background view for NSScrubber.
*/

import Cocoa

private class CustomSelectionBackgroundView: NSScrubberSelectionView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.systemBlue.set()
        NSBezierPath(roundedRect: dirtyRect, xRadius: 6, yRadius: 6).fill()
    }
    
}

// MARK: -

class CustomSelectionBackgroundStyle: NSScrubberSelectionStyle {
    override func makeSelectionView () -> NSScrubberSelectionView? {
        return CustomSelectionBackgroundView()
    }
    
}

