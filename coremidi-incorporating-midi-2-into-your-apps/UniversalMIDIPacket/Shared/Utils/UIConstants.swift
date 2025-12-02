/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Constants that specify layout and color settings.
*/

import Foundation
import CoreGraphics
import SwiftUI

enum UIConstants {
    
    static let defaultMargin: CGFloat = 20.0
    static let defaultCornerRadius: CGFloat = 10.0
    static let cellSize: CGFloat = 15.0

    static let backgroundTint = 0.1
    static let backgroundColor = Color.secondary.opacity(UIConstants.backgroundTint)
    static let selectedColor: Color = .blue
    
}
