/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension of DetailViewController that implements UIImagePickerControllerDelegate.
*/

import UIKit

extension DetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // UIKit calls this method when the user finishes picking an item with UIImagePickerController.
    // image.jpegData may fail for unsupported image formats. This sample doesn't
    // handle unsupported formats because that isn't the focus.
    //
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage, let imageData = image.jpegData(compressionQuality: 1),
            let imageURL = info[.imageURL] as? URL else {
                print("Failed to get JPG data and URL of the picked image.")
                return
        }
        
        // Save the full image to the cache folder. The image name from Photo Library should be unique,
        // so this sample doesn’t need to create a unique name for it.
        //
        let imageName = imageURL.lastPathComponent
        let cacheURL = cacheFolder.appendingPathComponent(imageName)
        do {
            try imageData.write(to: cacheURL, options: .atomic)
        } catch {
            print("Failed to save an image file: \(cacheURL)")
        }
        
        // Update document and collectionView, then dismiss the image picker.
        //
        var snapshot = diffableImageSource.snapshot()
        snapshot.insertItems([ImageItem(name: imageName, thumbnail: imageData.thumbnail())], beforeItem: plusCircelItem)
        diffableImageSource.apply(snapshot)
        
        document?.addUnsavedNewImageURL(cacheURL)
        dismiss(animated: true)
    }
    
    // UIKit calls the UIImagePickerControllerDelegate method when the user taps the cancel button in UIImagePickerController.
    //
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
}
