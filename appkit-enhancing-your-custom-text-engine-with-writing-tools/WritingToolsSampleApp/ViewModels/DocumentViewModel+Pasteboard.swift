/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Pasteboard handling for the custom text document editor view model.
*/

import Cocoa

// MARK: - Pasteboard handling
extension DocumentViewModel {
    func cutToPasteBoard() {
        if copyToPasteBoard() {
            deleteSelectedText()
        }
    }
    
    @discardableResult
    func copyToPasteBoard() -> Bool {
        guard let copySelection = firstSelection,
              let copyRange = firstRangeFromSelection(copySelection), copyRange.length > 0 else {
            return false
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        let attributedString = selectedAttributedStrings.reduce(NSMutableAttributedString()) {
            (result, attributedString) -> NSMutableAttributedString in result.append(attributedString)
            return result
        } as NSAttributedString
        
        // Set multiple pasteboard types for better compatibility.
        let types: [NSPasteboard.PasteboardType] = [.rtfd, .rtf, .string]
        pasteboard.declareTypes(types, owner: nil)

        // Set rich text format directory (RTFD) data.
        if let rtfdData = attributedString.rtfd(from: NSRange(location: 0, length: attributedString.length)) {
            pasteboard.setData(rtfdData, forType: .rtfd)
        }

        // Set rich text format (RTF) data.
        do {
            let data = try attributedString.data(
                from: NSRange(location: 0, length: attributedString.length),
                documentAttributes: [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.rtf])
            pasteboard.setData(data, forType: .rtf)
        } catch {
            print("Could not set RTF data: \(error)")
        }
    
        // Set plain string data.
        pasteboard.setString(attributedString.string, forType: .string)

        return true
    }

    func pasteToDocument() {
        guard let pasteSelection = firstSelection,
              let pasteRange = firstRangeFromSelection(pasteSelection) else {
            return
        }
        
        let pasteboard = NSPasteboard.general

        for item in pasteboard.pasteboardItems ?? [] {
            print("Available types: \(item.types)")
        }

        let availableTypes = pasteboard.types ?? []
        let attributedStringToPaste: NSAttributedString?

        // Try RTFD first (richest format).
        if availableTypes.contains(.rtfd), let rtfdData = pasteboard.data(forType: .rtfd) {
            attributedStringToPaste = try? NSAttributedString(data: rtfdData,
                options: [.documentType: NSAttributedString.DocumentType.rtfd], documentAttributes: nil)
        }
        
        // Try RTF next.
        else if availableTypes.contains(.rtf), let rtfData = pasteboard.data(forType: .rtf) {
            attributedStringToPaste = try? NSAttributedString(data: rtfData,
                options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
        }
        
        // Fall back to plain string.
        else if availableTypes.contains(.string), let string = pasteboard.string(forType: .string) {
            attributedStringToPaste = NSAttributedString(string: string)
        } else {
            attributedStringToPaste = nil
        }

        if let attributedStringToPaste {
            self.replaceText(inRange: pasteRange, with: attributedStringToPaste, applyingDefaultAttributes: false)
            let rangeAfterPaste = NSRange(location: pasteRange.location - pasteRange.length + attributedStringToPaste.length, length: 0)
            self.setCaretLocation(textRange(forRange: rangeAfterPaste).location)
            return
        }
        
        print("Unable to paste")
    }

    // MARK: - Services Menu Support

    /// Reads selection from pasteboard for Services menu operations.
    func readSelectionFromPasteboard(_ pboard: NSPasteboard) -> Bool {
        guard let range = firstSelectedRange else {
            return false
        }

        let availableTypes = pboard.types ?? []
        let attributedStringToPaste: NSAttributedString?

        if availableTypes.contains(.rtf), let rtfData = pboard.data(forType: .rtf) {
            attributedStringToPaste = try? NSAttributedString(data: rtfData,
                options: [.documentType: NSAttributedString.DocumentType.rtf], documentAttributes: nil)
        } else if availableTypes.contains(.string), let string = pboard.string(forType: .string) {
            attributedStringToPaste = NSAttributedString(string: string)
        } else {
            attributedStringToPaste = nil
        }

        if let attributedStringToPaste {
            replaceText(inRange: range, with: attributedStringToPaste)
            return true
        }

        return false
    }

    /// Writes selection to pasteboard for Services menu operations.
    func writeSelectionToPasteboard(_ pboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) -> Bool {
        let attributedString = firstSelectedAttributedString

        if types.contains(.rtfd) {
            let data = attributedString.rtfd(from: .init(location: 0, length: attributedString.length))
            pboard.setData(data, forType: .rtfd)
        }
        if types.contains(.rtf) {
            let data = attributedString.rtf(from: .init(location: 0, length: attributedString.length))
            pboard.setData(data, forType: .rtf)
        }
        if types.contains(.string) {
            pboard.setString(attributedString.string, forType: .string)
        }

        return true
    }
}
