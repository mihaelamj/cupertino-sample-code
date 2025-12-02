/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extends the pasteboard class.
*/

#if canImport(UIKit)
import UIKit

func writeToPasteboard(_ string: String) {
    UIPasteboard.general.string = string
}

#elseif canImport(AppKit)
import AppKit

func writeToPasteboard(_ string: String) {
    NSPasteboard.general.setString(string, forType: .string)
}

#endif
