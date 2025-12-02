/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extension for generating image data for landmark entity.
*/

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension LandmarkEntity {
    var imageRepresentationData: Data {
        get throws {
            try loadAssetData(named: self.landmark.backgroundImageName)
        }
    }

    var thumbnailRepresentationData: Data {
        get throws {
            try loadAssetData(named: self.landmark.thumbnailImageName)
        }
    }

    private func loadAssetData(named name: String) throws -> Data {
        struct ImageCreationError: Error {}
        #if canImport(UIKit)
        let image = UIImage(named: name)
        if let imageData = image?.pngData() {
            return imageData
        } else {
            throw ImageCreationError()
        }
        #elseif canImport(AppKit)
        guard let image = NSImage(named: name) else {
            throw ImageCreationError()
        }
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            throw ImageCreationError()
        }
        return pngData
        #else
        throw ImageCreationError()
        #endif
    }
}
