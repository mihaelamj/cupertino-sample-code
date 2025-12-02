/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements the view controller responsible for reviewing sorted face-quality scores for previously captured faces.
*/

import UIKit

class SavedFaceCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
}

class SavedFacesViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    var savedFaces = [SavedFacesDataSource.SavedFace]()
    var itemSize = CGSize.zero
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Sort faces in descending quality-score order.
        savedFaces.sort { $0.qualityScore < $1.qualityScore }

        let desiredItems = CGFloat(3)
        // Set item size so there are desiredItems per each line.
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        let sectionInset = layout.sectionInset
        let availableWidth = collectionView.bounds.width - sectionInset.left - sectionInset.right
        let size = floor(availableWidth / desiredItems - layout.minimumInteritemSpacing * (desiredItems - 1))
        self.itemSize = CGSize(width: size, height: size)
    }
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return savedFaces.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SavedFaceCell", for: indexPath) as? SavedFaceCell else {
            fatalError("Unexpected cell class")
        }
        let savedFace = savedFaces[indexPath.item]
        let faceImage = UIImage(contentsOfFile: savedFace.url.path)
        cell.imageView.image = faceImage
        cell.label.text = "\(savedFace.qualityScore)"
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return itemSize
    }
}
