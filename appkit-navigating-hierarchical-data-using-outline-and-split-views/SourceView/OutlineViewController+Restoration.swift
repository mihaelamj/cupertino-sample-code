/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
State restoration support for OutlineViewController.
*/

import Foundation

// MARK: -

extension OutlineViewController {
    
    // A restorable key for the currently selected outline node on state restoration.
    private static let savedSelectionKey = "savedSelectionKey"

    /// The key paths for window restoration (including the view controller).
    override class var restorableStateKeyPaths: [String] {
        var keys = super.restorableStateKeyPaths
        keys.append(savedSelectionKey)
        return keys
    }

    /// An encode state that helps save the restorable state of this view controller.
    override func encodeRestorableState(with coder: NSCoder) {
        coder.encode(treeController.selectionIndexPaths, forKey: OutlineViewController.savedSelectionKey)
        super.encodeRestorableState(with: coder)
    }

    /** A decode state that helps restore any previously stored state.
        Note that when "Close windows when quitting an app" is in a selected state in the System Preferences General pane,
        selection restoration works if you choose Option-Command-Quit.
    */
    override func restoreState(with coder: NSCoder) {
        super.restoreState(with: coder)
        
        // Restore the selected indexPaths.
        if let savedSelectedIndexPaths =
            coder.decodeObject(forKey: OutlineViewController.savedSelectionKey) as? [IndexPath] {
            treeController.setSelectionIndexPaths(savedSelectedIndexPaths)
        }
    }
    
}
