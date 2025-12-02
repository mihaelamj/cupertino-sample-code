/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Color Management support for index and name.
*/

import Foundation

#if os(macOS)
import Cocoa
typealias PlatformSpecificColor = NSColor
#else
import UIKit
typealias PlatformSpecificColor = UIColor
#endif

enum ColorIndex: Int {
    case white = 0
    case red
    case green
    case yellow
    
    var name: String {
        switch self {
        case .white:  return NSLocalizedString("White", comment: "")
        case .red:    return NSLocalizedString("Red", comment: "")
        case .green:  return NSLocalizedString("Green", comment: "")
        case .yellow: return NSLocalizedString("Yellow", comment: "")
        }
    }
    
    var color: PlatformSpecificColor {
        switch self {
        case .white:  return PlatformSpecificColor.white
        case .red:    return PlatformSpecificColor.red
        case .green:  return PlatformSpecificColor.green
        case .yellow: return PlatformSpecificColor.yellow
        }
    }
}
