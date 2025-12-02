/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This file contains both the carousel container view class, and a definition for the subclass
            of `UIAccessibilityElement` we use to represent the carousel.
*/

import UIKit

/**
    The custom carousel accessibility element is a core part of this sample.
    It is illustrating a way in which we choose to tweak the accessibility experience in a unique and interesting way.
    If we leave the collection view as is, then the VoiceOver user has to swipe to the end of the carousel
    before they can reach either button or the data for the dogs, meaning that they will only ever be able to
    get to the data for the last dog in the carousel through swiping alone. We instead create this custom element,
    and make it an adjustable element that responds to `accessibilityIncrement` and `accessibilityDecrement`,
    so that when a user swipes from it, they swipe immediately to the favorite and gallery buttons, then on to the data,
    for the specific dog. In some ways, we've transformed the collection view into acting more like a picker.
*/
/// - Tag: CarouselAccessibilityElement
class CarouselAccessibilityElement: UIAccessibilityElement {
    // MARK: Properties

    var currentDog: Dog?

    // MARK: Initializers

    init(accessibilityContainer: Any, dog: Dog?) {
        super.init(accessibilityContainer: accessibilityContainer)
        currentDog = dog
    }

    /// This indicates to the user what exactly this element is supposed to be.
    override var accessibilityLabel: String? {
        get {
            return "Dog Picker"
        }
        set {
            super.accessibilityLabel = newValue
        }
    }

    override var accessibilityValue: String? {
        get {
            if let currentDog = currentDog {
                return currentDog.name
            }

            return super.accessibilityValue
        }

        set {
            super.accessibilityValue = newValue
        }
    }

    // This tells VoiceOver that our element will support the increment and decrement callbacks.
    /// - Tag: accessibility_traits
    override var accessibilityTraits: UIAccessibilityTraits {
        get {
            return .adjustable
        }
        set {
            super.accessibilityTraits = newValue
        }
    }

    /**
        A convenience for forward scrolling in both `accessibilityIncrement` and `accessibilityScroll`.
        It returns a `Bool` because `accessibilityScroll` needs to know if the scroll was successful.
    */
    func accessibilityScrollForward() -> Bool {

        // Initialize the container view which will house the collection view.
        guard let containerView = accessibilityContainer as? DogCarouselContainerView else {
            return false
        }
        
        // Store the currently focused dog and the list of all dogs.
        guard let currentDog = currentDog, let dogs = containerView.dogs else {
            return false
        }

        // Get the index of the currently focused dog from the list of dogs (if it's a valid index).
        guard let index = dogs.firstIndex(of: currentDog), index < dogs.count - 1 else {
            return false
        }

        // Scroll the collection view to the currently focused dog.
        containerView.dogCollectionView.scrollToItem(
            at: IndexPath(row: index + 1, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
        
        return true
    }

    /**
        A convenience for backward scrolling in both `accessibilityIncrement` and `accessibilityScroll`.
        It returns a `Bool` because `accessibilityScroll` needs to know if the scroll was successful.
    */
    func accessibilityScrollBackward() -> Bool {
        guard let containerView = accessibilityContainer as? DogCarouselContainerView else {
            return false
        }

        guard let currentDog = currentDog, let dogs = containerView.dogs else {
            return false
        }

        guard let index = dogs.firstIndex(of: currentDog), index > 0 else {
            return false
        }

        containerView.dogCollectionView.scrollToItem(
            at: IndexPath(row: index - 1, section: 0),
            at: .centeredHorizontally,
            animated: true
        )

        return true
    }

    // MARK: Accessibility

    /*
        Overriding the following two methods allows the user to perform increment and decrement actions
        (done by swiping up or down).
    */
    /// - Tag: accessibility_increment_decrement
    override func accessibilityIncrement() {
        // This causes the picker to move forward one if the user swipes up.
        _ = accessibilityScrollForward()
    }
    
    override func accessibilityDecrement() {
        // This causes the picker to move back one if the user swipes down.
        _ = accessibilityScrollBackward()
    }

    /*
        This will cause the picker to move forward or backwards on when the user does a 3-finger swipe,
        depending on the direction of the swipe. The return value indicates whether or not the scroll was successful,
        so that VoiceOver can alert the user if it was not.
    */
    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        if direction == .left {
            return accessibilityScrollForward()
        } else if direction == .right {
            return accessibilityScrollBackward()
        }
        return false
    }

}

/**
    The carousel container is a container view for the carousel collection view and the favorite and gallery button.
    We subclass it so that we can override its `accessibilityElements` to exclude the collection view
    and use our custom element instead, and so that we can add and remove the gallery buton as
    an accessibility element as it appears and disappears.
*/
class DogCarouselContainerView: UIView {
    // MARK: Properties

    @IBOutlet weak var dogCollectionView: UICollectionView!
    @IBOutlet weak var galleryButton: UIButton!

    var currentDog: Dog? {
        didSet {
            _accessibilityElements = nil

            if let currentDog = currentDog, let carouselAccessibilityElement = carouselAccessibilityElement {
                carouselAccessibilityElement.currentDog = currentDog
            }
        }
    }

    var dogs: [Dog]?

    // MARK: Accessibility

    var carouselAccessibilityElement: CarouselAccessibilityElement?

    // Like in the `DogStatsView`, we need to cache `accessibilityElements`. See that file for an explanation why.
    /// - Tag: using_carousel_accessibility_element
    private var _accessibilityElements: [Any]?

    override var accessibilityElements: [Any]? {
        get {
            guard _accessibilityElements == nil else {
                return _accessibilityElements
            }

            guard let currentDog = currentDog else {
                return _accessibilityElements
            }

            let carouselAccessibilityElement: CarouselAccessibilityElement
            if let theCarouselAccessibilityElement = self.carouselAccessibilityElement {
                carouselAccessibilityElement = theCarouselAccessibilityElement
            } else {
                carouselAccessibilityElement = CarouselAccessibilityElement(
                    accessibilityContainer: self,
                    dog: currentDog
                )
                
                carouselAccessibilityElement.accessibilityFrameInContainerSpace = dogCollectionView.frame
                self.carouselAccessibilityElement = carouselAccessibilityElement
            }

            // Only show the gallery button if we have multiple images.
            if currentDog.images.count > 1 {
                _accessibilityElements = [carouselAccessibilityElement, galleryButton!]
            } else {
                _accessibilityElements = [carouselAccessibilityElement]
            }

            return _accessibilityElements
        }
        
        set {
            _accessibilityElements = newValue
        }
    }
}
