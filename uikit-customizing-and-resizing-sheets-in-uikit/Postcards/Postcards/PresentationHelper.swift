/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A helper class for injecting presentation settings.
*/

import UIKit

extension UISheetPresentationController.Detent.Identifier {
    static let small = UISheetPresentationController.Detent.Identifier("small")
}

class PresentationHelper {
    
    static let sharedInstance = PresentationHelper()
    var largestUndimmedDetentIdentifier: UISheetPresentationController.Detent.Identifier = .medium
    var prefersScrollingExpandsWhenScrolledToEdge: Bool = false
    var prefersEdgeAttachedInCompactHeight: Bool = true
    var widthFollowsPreferredContentSizeWhenEdgeAttached: Bool = true
}
