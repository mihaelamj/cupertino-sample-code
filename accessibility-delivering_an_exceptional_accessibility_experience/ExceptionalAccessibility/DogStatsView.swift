/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Contains the `DogStatsView` class.
*/

import UIKit

/**
    This view is a collection of labels that house the data for each dog.
    There are 4 properties that each dog has, so 8 labels in total: a title label for what the data is
    and then a content label for the value.
*/
/// - Tag: DogStatsView
class DogStatsView: UIView {
    // MARK: Properties

    @IBOutlet var nameTitleLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var breedTitleLabel: UILabel!
    @IBOutlet var breedLabel: UILabel!
    @IBOutlet var ageTitleLabel: UILabel!
    @IBOutlet var ageLabel: UILabel!
    @IBOutlet var weightTitleLabel: UILabel!
    @IBOutlet var weightLabel: UILabel!

    var dog: Dog? = nil {
        didSet {
            // We reset our cached elements to nil when we change dog objects so `accessibilityElements` are recomputed.
            _accessibilityElements = nil
            guard let dog = dog else {
                return
            }

            nameLabel.text = dog.name
            breedLabel.text = dog.breed
            ageLabel.text = "\(dog.age) years"
            weightLabel.text = "\(dog.weight) lbs"
        }
    }

    // MARK: Accessibility Logic

    /*
        VoiceOver relies on `accessibilityElements` returning an array of consistent objects that persist
        as the user swipes through an app. We therefore have to cache our array of computed `accessibilityElements`
        so that we don't get into an infinite loop of swiping. We reset this cached array whenever a new dog object is set
        so that `accessibilityElements` can be recomputed.
    */
    /// - Tag: grouping_elements
    private var _accessibilityElements: [Any]?

    override var accessibilityElements: [Any]? {
        get {
            // Return the accessibility elements if we've already created them.
            if let _accessibilityElements = _accessibilityElements {
                return _accessibilityElements
            }

            /*
                We want to create a custom accessibility element that represents a grouping of each
                title and content label pair so that the VoiceOver user can interact with them as a unified element.
                This is important because it reduces the amount of times the user has to swipe through the display
                to find the information they're looking for, and because without grouping the labels,
                the content labels lose the context of what they represent.
            */
            var elements = [UIAccessibilityElement]()
            let nameElement = UIAccessibilityElement(accessibilityContainer: self)
            nameElement.accessibilityLabel = "\(nameTitleLabel.text!), \(nameLabel.text!)"

            /*
                This tells VoiceOver where the object should be onscreen. As the user
                touches around with their finger, we can determine if an element is below
                their finger.
            */
            nameElement.accessibilityFrameInContainerSpace = nameTitleLabel.frame.union(nameLabel.frame)
            elements.append(nameElement)
            
            let ageElement = UIAccessibilityElement(accessibilityContainer: self)
            ageElement.accessibilityLabel = "\(ageTitleLabel.text!), \(ageLabel.text!)"
            ageElement.accessibilityFrameInContainerSpace = ageTitleLabel.frame.union(ageLabel.frame)
            elements.append(ageElement)
            
            let breedElement = UIAccessibilityElement(accessibilityContainer: self)
            breedElement.accessibilityLabel = "\(breedTitleLabel.text!), \(breedLabel.text!)"
            breedElement.accessibilityFrameInContainerSpace = breedTitleLabel.frame.union(breedLabel.frame)
            elements.append(breedElement)
            
            let weightElement = UIAccessibilityElement(accessibilityContainer: self)
            weightElement.accessibilityLabel = "\(weightTitleLabel.text!), \(weightLabel.text!)"
            weightElement.accessibilityFrameInContainerSpace = weightTitleLabel.frame.union(weightLabel.frame)
            elements.append(weightElement)
            
            _accessibilityElements = elements

            return _accessibilityElements
        }
        
        set {
            _accessibilityElements = newValue
        }
    }
}
