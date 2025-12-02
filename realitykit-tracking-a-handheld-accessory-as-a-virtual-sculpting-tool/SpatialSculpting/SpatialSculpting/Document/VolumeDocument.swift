/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The file format for saving sculptures to.
*/

import SwiftUI
import UniformTypeIdentifiers

enum VolumeDocumentError: Error {
    case unexpectedPixelFormat(MTLPixelFormat)
    case missingFileContents
    case unexpectedFileSize(Int, Int)
    case failedToAccessSecurityScopedResource
}

struct VolumeDocument: FileDocument {
    static let utType = UTType(exportedAs: "com.spatial-sculpting.volume-document", conformingTo: nil)
    static var readableContentTypes: [UTType] { [utType] }
    var data: Data

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw VolumeDocumentError.missingFileContents
        }
        self.data = data
    }

    init(texture: MTLTexture) throws {
        guard texture.pixelFormat == .r32Float else {
            throw VolumeDocumentError.unexpectedPixelFormat(texture.pixelFormat)
        }
        let bytesPerRow = 4 * texture.width
        let bytesPerImage = bytesPerRow * texture.height
        let sizeBytes = bytesPerImage * texture.depth
        var data = Data(count: sizeBytes)
        data.withUnsafeMutableBytes { pointer in
            texture.getBytes(pointer.baseAddress!,
                             bytesPerRow: bytesPerRow,
                             bytesPerImage: bytesPerImage,
                             from: MTLRegionMake3D(0, 0, 0, texture.width, texture.height, texture.depth),
                             mipmapLevel: 0,
                             slice: 0)
        }

        self.data = data
    }

    @MainActor
    static func loadFromURL(_ url: URL, texture: MTLTexture) throws {
        guard texture.pixelFormat == .r32Float else {
            throw VolumeDocumentError.unexpectedPixelFormat(texture.pixelFormat)
        }
        let bytesPerRow = 4 * texture.width
        let bytesPerImage = bytesPerRow * texture.height
        let sizeBytes = bytesPerImage * texture.depth

        guard url.startAccessingSecurityScopedResource() else {
            throw VolumeDocumentError.failedToAccessSecurityScopedResource
        }
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        let data = try Data(contentsOf: url, options: [.alwaysMapped])
        guard data.count == sizeBytes else {
            throw VolumeDocumentError.unexpectedFileSize(data.count, sizeBytes)
        }
        data.withUnsafeBytes { pointer in
            texture.replace(region: MTLRegionMake3D(0, 0, 0, texture.width, texture.height, texture.depth),
                            mipmapLevel: 0,
                            slice: 0,
                            withBytes: pointer.baseAddress!,
                            bytesPerRow: bytesPerRow,
                            bytesPerImage: bytesPerImage)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: self.data)
    }
}
