/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of menu request support for the documentation view.
*/

import Cocoa

extension DocumentView: @preconcurrency NSServicesMenuRequestor {
    func readSelection(from pboard: NSPasteboard) -> Bool {
        return viewModel.readSelectionFromPasteboard(pboard)
    }
        
    func writeSelection(to pboard: NSPasteboard, types: [NSPasteboard.PasteboardType]) -> Bool {
        return viewModel.writeSelectionToPasteboard(pboard, types: types)
    }
    
    override func validRequestor(forSendType sendType: NSPasteboard.PasteboardType?, returnType: NSPasteboard.PasteboardType?) -> Any? {
        if sendType == .rtfd || sendType == .rtf || sendType == .string {
            return self
        }
        
        return super.validRequestor(forSendType: sendType, returnType: returnType)
    }
}
