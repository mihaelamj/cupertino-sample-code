/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that adds a method to enumerate a view controller hierarchy.
*/

import UIKit

extension UIViewController {
    // Executes the provided closure on the current view controller
    // and on all of its descendants in the view controller hierarchy.
    func enumerateHierarchy(_ closure: (UIViewController) -> Void) {
        closure(self)
        
        for child in children {
            child.enumerateHierarchy(closure)
        }
    }
}
