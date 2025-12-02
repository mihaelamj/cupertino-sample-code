/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension of DetailViewController that manages the collection view.
*/

import UIKit

extension DetailViewController {
    // If the user is editing and tapping the last cell, present an image picker.
    // Otherwise, present the full image.
    // In the latter case, try to load the image in the document bundle first, then check the cache
    // if the image doesn't exist in the document bundle.
    //
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if isEditing && indexPath.item == collectionView.numberOfItems(inSection: 0) - 1 {
            presentImagePicker()
        } else if let imageItem = diffableImageSource.itemIdentifier(for: indexPath) {
            retrieveAndPresentImage(with: imageItem.name)
        }
    }
    
    private func retrieveAndPresentImage(with imageName: String) {
        document?.retrieveImageAsynchronously(with: imageName) { image in
            DispatchQueue.main.async {
                if let image = image {
                    self.presentImageViewController(image: image)
                    return
                }
                let imageURL = self.cacheFolder.appendingPathComponent(imageName)
                guard let image = UIImage(contentsOfFile: imageURL.path) else { return }
                self.presentImageViewController(image: image)
            }
        }
    }
    
    private func presentImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.allowsEditing = false
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
    
    private func presentImageViewController(image: UIImage) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "FullImageNC")
        guard let navController = viewController as? UINavigationController,
              let imageViewController = navController.topViewController as? ImageViewController else {
                return
        }
        imageViewController.fullImage = image
        present(navController, animated: true)
    }
}

extension DetailViewController: ImagCVCellDelegate {
    func deleteCell(_ cell: UICollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell),
              let imageItem = diffableImageSource.itemIdentifier(for: indexPath) else {
            return
        }

        // If the user added a deleted item in this edit session, remove it from unsavedNewImageURLs.
        // Otherwise, record the deletion.
        //
        let firstIndex = document?.unsavedNewImageURLs.firstIndex {
            $0.lastPathComponent == imageItem.name
        }
        if let index = firstIndex {
            document?.removeUnsavedNewImageURL(at: index)
        } else {
            document?.addUnsavedDeletedImageName(imageItem.name)
        }
        // Update the collectionView.
        //
        var snapshot = diffableImageSource.snapshot()
        snapshot.deleteItems([imageItem])
        diffableImageSource.apply(snapshot)
    }
}

