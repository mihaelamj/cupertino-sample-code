/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A processed photo data model that contains the image and color scheme of
  a sticker, with its color scheme as a collection of colors.
*/

import SwiftUI

/// A structure that represents a processed photo to use for sticker creation.
///
/// `ProcessedPhoto` stores the processed image for a sticker, along with
/// its associated color scheme. The system creates this structure after processing
/// a photo for use as a sticker in the app.
///
/// - Properties:
///   - sticker: The processed image to use as a sticker.
///   - colorScheme: A collection of dominant colors from the original photo.
struct ProcessedPhoto {
    let sticker: Image
    let colorScheme: PhotoColorScheme
}

struct PhotoColorScheme {
    let colors: [Color]
}

struct ProcessedPhotoResult: Identifiable {
    let id: SelectedPhoto.ID
    let processedPhoto: ProcessedPhoto
}
