/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Image utilties for multiplatform code.
*/

import SwiftUI

// MARK: - PlatformImage
/// Platform image is a typealias that aliases to either NSImage or UIImage, depending on the platform.
/// This enables the rest of the code to be platform-agnostic.
#if os(macOS)
typealias PlatformImage = NSImage
#elseif os(iOS)
typealias PlatformImage = UIImage
#endif

#if os(macOS)
/// This is a convenience init for PlatformImage in macOS. iOS already has an init with this signature.
extension PlatformImage {
    convenience init(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
    }
}
#endif

// MARK: - Image Extension
extension Image {
    /// This is an initializer for SwiftUI's Image, which accepts a platform-agnostic image.
    init(_ image: PlatformImage) {
        #if os(macOS)
        self.init(nsImage: image)
        #elseif os(iOS)
        self.init(uiImage: image)
        #endif
    }
}

// MARK: - CIImage Extension
extension CIImage {
    /// This is a convenience intializer for CIImage, which accepts a platform-agnostic image.
    convenience init(_ image: PlatformImage) {
        #if os(macOS)
        self.init(cgImage: image.cgImage(forProposedRect: nil, context: nil, hints: nil)!)
        #elseif os(iOS)
        self.init(cgImage: image.cgImage!)
        #endif
    }
}
