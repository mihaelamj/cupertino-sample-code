/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view controller for this sample.
*/

import UIKit
import Combine

class ViewController: UIViewController {

    // Available color choices in Preferences.
    enum BackgroundColors: Int {

        // These values match the ones defined in the Values array
        // contained in the Root.plist file of the Settings bundle.
        case blue = 1
        case teal = 2
        case indigo = 3
        
        func currentColor() -> UIColor {
            var color = UIColor.systemBlue
            switch self {
            case .blue:
                color = UIColor.systemBlue
            case .teal:
                color = UIColor.systemTeal
            case .indigo:
                color = UIColor.systemIndigo
            }
            return color
        }
    }

    /// - Tag: combine
    var subscriber: AnyCancellable?   // Subscriber of preference changes.

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's initial background color to the color specified in Preferences.
        if let colorSetting = BackgroundColors(rawValue: UserDefaults.standard.backgroundColorValue) {
            view.backgroundColor = colorSetting.currentColor()
        }
        
        // Listen for changes to the background color preference made in the Preferences window.
        subscriber = UserDefaults.standard
            .publisher(for: \.backgroundColorValue, options: [.initial, .new])
            .map( { BackgroundColors(rawValue: $0)?.currentColor() })
            .assign(to: \UIView.backgroundColor, on: self.view)
    }

}

// Extend `UserDefaults` for quick access to preference values.

/// - Tag: UserDefaults
extension UserDefaults {

    @objc dynamic var backgroundColorValue: Int {
        return integer(forKey: "backgroundColorValue")
    }
    
    @objc dynamic var someRandomOption: Bool {
        return bool(forKey: "someRandomOption")
    }

}
