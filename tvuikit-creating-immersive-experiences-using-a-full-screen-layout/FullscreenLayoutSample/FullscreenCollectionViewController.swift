/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A simple `UICollectionViewController` that uses `TVCollectionViewFullScreenLayout` as its layout.
*/

import TVUIKit

private let reuseIdentifier = "Cell"

private let sourceCount = 5

class FullscreenCollectionViewController: UICollectionViewController {
    
    fileprivate let fullscreenLayout = TVCollectionViewFullScreenLayout()
    
    init() {
        super.init(collectionViewLayout: fullscreenLayout)
    }
    
    required init?(coder: NSCoder) {
        super.init(collectionViewLayout: fullscreenLayout)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(collectionViewLayout: fullscreenLayout)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fullscreenLayout.interitemSpacing = 10
        fullscreenLayout.maskInset = .zero
        
        collectionView!.register(FullscreenCell.self, forCellWithReuseIdentifier: reuseIdentifier)
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sourceCount
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // This collectionView simply uses a `FullscreenCell`.
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? FullscreenCell else {
            fatalError("unknown cell type, or unable to dequeue the correct cell from collectionView.")
        }
    
        // Call the helper method to set the content and also the action for the button.
        cell.set(backgroundImage: image(for: indexPath), title: title(for: indexPath)) {
            UIView.animate(withDuration: 0.7, animations: {
                // Use `maskAmount` 0 when the content should take over the entire view's real state.
                self.fullscreenLayout.maskAmount = self.fullscreenLayout.maskAmount == 0 ? 1 : 0
            })
        }
    
        return cell
    }

    // MARK: Helper Methods
    fileprivate func image(for indexPath: IndexPath) -> UIImage? {
        return UIImage(named: "Food_\(indexPath.row + 1)")
    }
    
    fileprivate func title(for indexPath: IndexPath) -> String {
        return "Food item #\(indexPath.row + 1)"
    }
}
