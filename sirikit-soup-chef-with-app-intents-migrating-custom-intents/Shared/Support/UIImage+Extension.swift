/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A utility extension on `UIImageView` for visual appearance.
*/

import UIKit

extension UIImageView {
    public func applyRoundedCorners() {
        layer.cornerRadius = 8
        clipsToBounds = true
    }
}
