/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The representation of the image and thumbnail data.
*/

import Foundation
import ImageIO
import UniformTypeIdentifiers
import Photos
import CoreTransferable

class Asset: Identifiable, Hashable, Equatable {

    let id: String
    let file: URL?
    let data: Data?
    let thumbnail: CGImage?
    let photoAsset: PHAsset?

    init(file: URL, thumbnail: CGImage? = nil) {
        _ = file.startAccessingSecurityScopedResource()
        self.id = file.absoluteString
        self.file = file
        self.data = nil
        self.thumbnail = thumbnail
        self.photoAsset = nil
    }

    init(data: Data, thumbnail: CGImage? = nil, identifier: String) {
        self.id = identifier
        self.file = nil
        self.data = data
        self.thumbnail = thumbnail
        self.photoAsset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject
    }
    
    deinit {
        file?.stopAccessingSecurityScopedResource()
    }

    func hash(into hasher: inout Hasher) {
        return self.id.hash(into: &hasher)
    }
    var name: String {
        return self.file?.lastPathComponent ?? self.id
    }

    static func == (lhs: Asset, rhs: Asset) -> Bool {
        return lhs.id == rhs.id
    }

}

extension Asset {

    static private func loadThumbnail(from source: CGImageSource) -> CGImage? {

        // Use appropriate options for the CGImageSource to get HDR for
        // Gain Map HDR thumbnails.
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: 400,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceDecodeRequest: kCGImageSourceDecodeToHDR
        ]

        return CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary)

    }

    static func load(from fileURL: URL) -> Asset {

        _ = fileURL.startAccessingSecurityScopedResource()
        let asset: Asset
        if let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil),
           let thumbnail = loadThumbnail(from: source) {
            asset = Asset(file: fileURL, thumbnail: thumbnail)
        } else {
            asset = Asset(file: fileURL)
        }
        fileURL.stopAccessingSecurityScopedResource()

        return asset

    }

    static func load(from data: Data, identifier: String) -> Asset {

        if let source = CGImageSourceCreateWithData(data as CFData, nil),
           let thumbnail = loadThumbnail(from: source) {
            return Asset(data: data, thumbnail: thumbnail, identifier: identifier)
        } else {
            return Asset(data: data, identifier: identifier)
        }

    }

}
