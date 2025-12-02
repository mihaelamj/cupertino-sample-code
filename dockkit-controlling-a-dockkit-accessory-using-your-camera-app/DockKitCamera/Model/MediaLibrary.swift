/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Abstract:
 An object that writes photos and movies to a person's Photos library.
*/

import Foundation
import Photos
import UIKit

/// An object that writes photos and movies to a person's Photos library.
actor MediaLibrary {
    
    // Errors that the media library can throw.
    enum Error: Swift.Error {
        case unauthorized
        case saveFailed
    }
    
    /// Creates a media library object.
    init() {
    }
    
    // MARK: - Authorization
    
    private var isAuthorized: Bool {
        get async {
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            /// Determine whether the person has previously authorized `PHPhotoLibrary` access.
            var isAuthorized = status == .authorized
            // If the system can't determine the person's authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                // Request authorization to add media to the library.
                let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
                isAuthorized = status == .authorized
            }
            return isAuthorized
        }
    }

    // MARK: - Saving media
    
    /// Saves a movie to the Photos library.
    func save(movie: Movie) async throws {
        try await performChange {
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = true
            let creationRequest = PHAssetCreationRequest.forAsset()
            creationRequest.addResource(with: .video, fileURL: movie.url, options: options)
        }
    }
    
    // A template method for writing a change to a person's Photos library.
    private func performChange(_ change: @Sendable @escaping () -> Void) async throws {
        guard await isAuthorized else {
            throw Error.unauthorized
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                // Execute the change closure.
                change()
            }
        } catch {
            throw Error.saveFailed
        }
    }
}

