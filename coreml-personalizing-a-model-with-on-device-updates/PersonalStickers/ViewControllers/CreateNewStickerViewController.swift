/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View Controller that allows the user to pick an emoji for a new sticker.
*/

import UIKit

final class CreateNewStickerViewController: UICollectionViewController {
    private static let emojiList: [String.Element] = {
        let defaultEmoji = Array("🙉🙈🙊⁉️")
        
        guard let emojiFileURL = Bundle.main.url(forResource: "emoji", withExtension: "txt") else {
            return defaultEmoji
        }
        
        guard let emojiString = try? String(contentsOf: emojiFileURL) else {
            return defaultEmoji
        }
        
        return Array(emojiString)
    }()
    
    let cellIdentifier = "emojiCell"
    
    private var emojiList: [String.Element] {
        return CreateNewStickerViewController.emojiList
    }
    
    var selectedEmoji: Character?
        
    @IBSegueAction func makeTrainingViewController(coder: NSCoder, sender: Any?, segueIdentifier: String?) -> ProvideExampleDrawingsViewController? {
        guard let trainingViewController = ProvideExampleDrawingsViewController(coder: coder) else {
            print("Unable to create StickerTrainingViewController")
            return nil
        }
        guard let emoji = selectedEmoji else {
            print("StickerPickerViewCoontroller is attempting to display the TrainingViewController without selecting an emoji")
            return nil
        }
        trainingViewController.exampleDrawings = ExampleDrawingSet(for: emoji)
        return trainingViewController
    }
    
    @IBAction func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Collection View Data Source
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojiList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? EmojiCell ?? EmojiCell()
        cell.emoji = String(emojiList[indexPath.row])
        return cell
    }
    
    // MARK: - Collection View Delegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emoji = emojiList[indexPath.row]
        print("Selected \(emoji)")
        selectedEmoji = emoji
        performSegue(withIdentifier: "showTrainingView", sender: self)
    }
}
