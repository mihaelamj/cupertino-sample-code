/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The BNNS bitcrusher cross-platform support file.
*/

import Foundation
import SwiftUI

#if os(iOS)
typealias HostingController = UIHostingController
#elseif os(macOS)
typealias HostingController = NSHostingController

extension NSView {
	
	func bringSubviewToFront(_ view: NSView) {
	}
}
#endif
