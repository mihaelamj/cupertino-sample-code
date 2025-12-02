/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Adds the camera picker support to the main view controller.
*/

import UIKit

extension MainViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    /// Creates a controller that gives the user a view they can use to take a photo with the device's camera.
    var cameraPicker: UIImagePickerController {
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .camera
        return cameraPicker
    }

    /// The delegate method UIKit calls when the user takes a photo with the camera.
    /// - Parameters:
    ///   - picker: A picker controller the `cameraPicker` property created.
    ///   - info: A dictionary that contains the photo.
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: false)

        // Always return the original image.
        guard let originalImage = info[UIImagePickerController.InfoKey.originalImage] else {
            fatalError("Picker didn't have an original image.")
        }

        guard let photo = originalImage as? UIImage else {
            fatalError("The (Camera) Image Picker's image isn't a/n \(UIImage.self) instance.")
        }

        userSelectedPhoto(photo)
    }
}
