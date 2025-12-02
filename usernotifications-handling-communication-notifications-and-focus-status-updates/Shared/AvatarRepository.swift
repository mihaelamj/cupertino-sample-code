/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A simple repository example to cache suggested avatar images.
*/

import Foundation

enum AvatarRepositoryError: Error {
    case imageNotFound
}

class AvatarRepository {
    static let shared = AvatarRepository()
    private init() {}
    
    private var imageDataStore = [String: Data]()
    private var imageNameStore = [String: String]()

    func updateImageStore(avatarIdentifier: String, avatarImage: AvatarImage) {
        // Store in memory.
        switch avatarImage {
            case .imageName(let name):
                imageNameStore[avatarIdentifier] = name
            case .imageData(let data):
                imageDataStore[avatarIdentifier] = data
            case .systemImageNamed:
                break
        }
        // Store the image in the shared AppGroup container to allow access from the notification service.
    }
    
    /// Returns cached image data.
    /// - Parameters:
    ///   - identifier: Image identifier.
    ///   - completion: Image data, nil if not found.
    func imageData(identifier: String) throws -> Data {
        guard let image = imageDataStore[identifier] else {
            // Check if the image is stored via a shared AppGroup container.
            throw AvatarRepositoryError.imageNotFound
        }
        return image
    }
    
    /// Returns cached image name.
    /// - Parameter identifier: Image identifier.
    /// - Returns: Image name, throws AvatarRepositoryError.imageNotFound if not found.
    func imageName(identifier: String) throws -> String {
        guard let image = imageNameStore[identifier] else {
            // Check if the image is stored via a shared AppGroup container.
            throw AvatarRepositoryError.imageNotFound
        }
        return image
    }
}
