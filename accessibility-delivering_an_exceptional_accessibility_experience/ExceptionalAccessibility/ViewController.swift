/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller responsible for all interactions in this sample.
*/

import UIKit

/**
    This view controller manages the displayed views, links up the data by syncing dog objects
    across the relevant views, handles displaying and removing the modal view as well as responding
    to button presses in the carousel. It also serves as the data source for the collection view.
    */
class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // MARK: Properties

    @IBOutlet weak var carouselContainerView: DogCarouselContainerView!
    @IBOutlet weak var dogCollectionView: UICollectionView!
    @IBOutlet weak var galleryButton: UIButton!
    
    @IBOutlet weak var dogStatsView: DogStatsView!
    
    @IBOutlet weak var shelterInfoView: UIView!
    @IBOutlet weak var shelterNameLabel: UILabel!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var callButton: UIButton!
    
    var dogs = Dog.all

    var currentlyFocusedDog: Dog? = nil {
        // Every time we update our Dog object, we need to relay that change to all the views that care.
        didSet {
            if dogStatsView != nil {
                dogStatsView!.dog = currentlyFocusedDog
            }
            carouselContainerView.currentDog = currentlyFocusedDog
            shelterNameLabel.text = currentlyFocusedDog?.shelterName
            shelterInfoView.accessibilityLabel = currentlyFocusedDog?.shelterName
        }
    }
    let cellIdentifier = "dog collection view cell"

    /// - Tag: custom_actions
    override func viewDidLoad() {
        super.viewDidLoad()

        if !dogs.isEmpty {
            currentlyFocusedDog = dogs.first
            carouselContainerView.dogs = dogs
        }
        
        galleryButton.accessibilityLabel = "Show Gallery"
        
        shelterInfoView.isAccessibilityElement = true

        shelterInfoView.accessibilityCustomActions = [
            UIAccessibilityCustomAction(
                name: "Call",
                target: self,
                selector: #selector(activateCallButton)
            ),
            UIAccessibilityCustomAction(
                name: "Open address in Maps",
                target: self,
                selector: #selector(activateLocationButton)
            )
        ]
    }

    /// Called as a result of activating the "Open address in Maps" custom action.
    @objc
    func activateLocationButton() -> Bool {
        // Activate the location button.
        return true
    }

    /// Called as a result of activating the "Call" custom action.
    @objc
    func activateCallButton() -> Bool {
        // Activate the call button.
        return true
    }

    @IBAction func galleryButtonPressed(_ sender: Any) {
        guard let dogModalViewController = storyboard?.instantiateViewController(withIdentifier: "DogModalViewController") else {
            fatalError("Could not create a \"DogModalViewController\" from the storyboard.")
        }

        guard let dogModalView = dogModalViewController.view as? DogModalView else {
            fatalError("\"DogModalViewController\" not configured with a \"DogModalView\".")
        }

        // The gallery button shouldn't do anything if the currently focused dog doesn't have 2 or more images.
        guard let currentlyFocusedDog = currentlyFocusedDog, currentlyFocusedDog.images.count >= 2 else {
            return
        }

        // Make the images of the modal view accessible and add accessibility labels to these images and the close button.
        dogModalView.closeButton.accessibilityLabel = "Close"
        dogModalView.firstImageView.isAccessibilityElement = true
        dogModalView.firstImageView.accessibilityLabel = "Image 1"
        dogModalView.firstImageView.image = currentlyFocusedDog.images[0]
        dogModalView.secondImageView.isAccessibilityElement = true
        dogModalView.secondImageView.accessibilityLabel = "Image 2"
        dogModalView.secondImageView.image = currentlyFocusedDog.images[1]

        dogModalView.alpha = 0.0
        view.addSubview(dogModalView)

        UIView.animate(withDuration: 0.25, animations: {
            dogModalView.alpha = 1.0
        }, completion: { finished in
            if finished {
                /*
                 Once the modal gallery view has been animated in, we need to post a notification
                 to VoiceOver that the screen has changed so that it knows to update its focus
                 to the new content now displayed on top of the older content.
                 */
                UIAccessibility.post(notification: .screenChanged, argument: nil)
            }
        })
    }
    
    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dogs.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? DogCollectionViewCell else {
            fatalError("Expected a `\(DogCollectionViewCell.self)` but did not receive one.")
        }

        let dog = dogs[indexPath.item]
        cell.dogImageView.image = dog.featuredImage
        cell.isAccessibilityElement = true
        cell.accessibilityLabel = dog.name
        return cell
    }

    // MARK: UIScrollViewDelegate

    // This keeps the cells of the collection view centered.
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let layout = self.dogCollectionView?.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        let cellWidthIncludingSpacing = layout.itemSize.width + layout.minimumLineSpacing
        
        var offset = targetContentOffset.pointee
        let index = round((offset.x + scrollView.contentInset.left) / cellWidthIncludingSpacing)
        offset = CGPoint(x: index * cellWidthIncludingSpacing - scrollView.contentInset.left,
                         y: -scrollView.contentInset.top)
        targetContentOffset.pointee = offset
    }

    /**
        In `scrollViewDidScroll`, we calculate our new centered cell's index, then find the corresponding `Dog`
        in our array and update our current `Dog`. We also animate in or out the gallery button based on
        whether or not we want to show it for the new dog.
    */
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let flowLayout = dogCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }

        let itemWidth = flowLayout.itemSize.width
        let offset = dogCollectionView!.contentOffset.x / itemWidth
        let index = Int(round(offset))

        guard (0..<dogs.count).contains(index) else {
            return
        }

        let focusedDog = dogs[index]
        currentlyFocusedDog = focusedDog
        
        if focusedDog.images.count > 1 {
            if galleryButton.alpha == 0.0 {
                UIView.animate(withDuration: 0.25, animations: {
                    self.galleryButton.alpha = 1.0
                })
            }
        } else if galleryButton.alpha == 1.0 {
            UIView.animate(withDuration: 0.25, animations: {
                self.galleryButton.alpha = 0.0
            })
        }
        
        /*
            The information for the dog displayed below the collection view updates as you scroll,
            but VoiceOver isn't aware that the views have changed their values. So we need to post
            a layout changed notification to let VoiceOver know it needs to update its current
            understanding of what's on screen.
        */
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }
}
