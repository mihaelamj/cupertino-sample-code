/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Text selection handling and manipulations for the custom text document editor view model.
*/

import Cocoa

// MARK: - Operations based on selection
extension DocumentViewModel {
    func deleteSelectedText() {
        guard let firstCaret = firstSelection?.textRanges.first else {
            return
        }
        
        for selection in currentSelections {
            for range in rangesFromSelection(selection) {
                replaceText(inRange: range, with: NSAttributedString(string: ""), applyingDefaultAttributes: false)
            }
        }
        setCaretLocation(firstCaret.location)
    }
    
    func selectAllDocumentText() {
        let selection = NSTextSelection(range: textContentStorage.documentRange, affinity: .downstream, granularity: .character)
        selectDocumentText(selection)
    }

    func selectDocumentText(inNSRange range: NSRange) {
        textLayoutManager.textSelections = [NSTextSelection(range: textRange(forRange: range), affinity: .downstream, granularity: .character)]
        viewModelDelegate?.selectionDidChange()
    }

    func selectDocumentText(_ selection: NSTextSelection) {
        textLayoutManager.textSelections = [selection]
        viewModelDelegate?.selectionDidChange()
    }
    
    func setCaretPosition(_ pos: NSTextSelection) {
        selectDocumentText(pos)
    }
    
    func setCaretLocation(_ loc: NSTextLocation) {
        selectDocumentText(NSTextSelection(loc, affinity: .upstream))
    }
}

// MARK: - Selection and Ranges conversions and utilities
extension DocumentViewModel {
    func firstRangeFromSelection(_ selection: NSTextSelection) -> NSRange? {
        guard let range = selection.textRanges.first else {
            return nil
        }

        let location = textContentStorage.offset(from: textContentStorage.documentRange.location, to: range.location)
        let length = textContentStorage.offset(from: range.location, to: range.endLocation)

        return NSRange(location: location, length: length)
    }
    
    func rangesFromSelection(_ selection: NSTextSelection) -> [NSRange] {
        let ranges = selection.textRanges
        var ret: [NSRange] = []
        
        for range in ranges {
            let location = textContentStorage.offset(from: textContentStorage.documentRange.location, to: range.location)
            let length = textContentStorage.offset(from: range.location, to: range.endLocation)
            ret.append(NSRange(location: location, length: length))
        }
        return ret
    }

    func offset(atLocation: NSTextLocation) -> Int {
        textContentStorage.offset(from: textContentStorage.documentRange.location, to: atLocation)
    }
    
    func offset(fromLocation: NSTextLocation, toLocation: NSTextLocation) -> Int {
        let start = offset(atLocation: fromLocation)
        let end = offset(atLocation: toLocation)
        
        return end - start
    }
    
    func location(forOffset offset: Int) -> NSTextLocation {
        let startLocation = textLayoutManager.documentRange.location
        guard let location = textContentStorage.location(startLocation, offsetBy: offset) else {
            // Return document start location as fallback.
            return textLayoutManager.documentRange.location
        }
        return location
    }
    
    func range(forTextRange range: NSTextRange) -> NSRange {
        NSRange(location: offset(atLocation: range.location), length: offset(fromLocation: range.location, toLocation: range.endLocation))
    }
    
    func textRange(forRange range: NSRange) -> NSTextRange {
        let startLocation = location(forOffset: range.location)
        let end = location(forOffset: range.location + range.length)
        
        guard let textRange = NSTextRange(location: startLocation, end: end) else {
            return NSTextRange(location: textLayoutManager.documentRange.location, end: textLayoutManager.documentRange.location)!
        }
        
        return textRange
    }
}

// MARK: - Positions handling
extension DocumentViewModel {
    /// Returns the text offset closest to the given point.
    func closestPosition(to point: CGPoint) -> Int? {
        let selections = textLayoutManager.textSelectionNavigation.textSelections(interactingAt: point,
                           inContainerAt: textLayoutManager.documentRange.location,
                           anchors: [],
                           modifiers: [],
                           selecting: true,
                           bounds: .zero)
        
        if let selection = selections.first, let range = selection.textRanges.first {
            return offset(atLocation: range.location)
        }

        print("Could not find closest position, returning nil")
        return nil
    }

    func selectionRects(for range: NSRange, excludingZeroSizeRects: Bool = true) -> [NSRect] {
        var rects = [NSRect]()
        
        if range.location == NSNotFound {
            return rects
        }
        let nsTextRange = textRange(forRange: range)
        
        textLayoutManager.enumerateTextSegments(in: nsTextRange, type: .selection, options: []) { (textRange, frame, baseline, textContainer) in
            if !excludingZeroSizeRects || (excludingZeroSizeRects && frame.size != .zero) {
                rects.append(frame)
            }
            
            return true
        }
        
        return rects
    }
    
    /// This finds the union of all selections.
    func unionSelectionRect(for range: NSRange) -> NSRect {
        let rects = selectionRects(for: range)
        guard let firstRect = rects.first else {
            print("Unable to obtain the first rectangle in given range.")
            return NSRect()
        }
        
        var unionRect = firstRect
        for rect in rects {
            unionRect = unionRect.union(rect)
        }

        return unionRect
    }

    func unionRect(for rects: [CGRect]) -> CGRect {
        guard let firstRect = rects.first else {
            print("Unable to obtain the first rectangle in given array of rectangles.")
            return CGRect()
        }
        
        var unionRect = firstRect
        for rect in rects {
            unionRect = unionRect.union(rect)
        }

        return unionRect
    }
}
