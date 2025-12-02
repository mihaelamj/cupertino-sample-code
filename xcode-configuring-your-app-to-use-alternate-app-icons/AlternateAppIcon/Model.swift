/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model representing the data the app displays in its interface.
*/

import UIKit
import SwiftUI
import OSLog

@MainActor
@Observable class Model {
    var appIcon: Icon
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Model")
    
    /// Initializes the model with the current state of the app's icon.
    init() {
        let iconName = UIApplication.shared.alternateIconName
        
        if let iconName, let icon = Icon(rawValue: iconName) {
            appIcon = icon
        } else {
            appIcon = .primary
        }
    }
    
    /// Change the app icon.
    func setAlternateAppIcon(icon: Icon) {
        // Set the icon name to nil to use the primary icon.
        let iconName: String? = (icon != .primary) ? icon.rawValue : nil
        
        // Avoid setting the name if the app already uses that icon.
        guard UIApplication.shared.alternateIconName != iconName else { return }
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error {
                self.logger.error("Failed request to update the app’s icon: \(error)")
            }
        }
        
        appIcon = icon
    }
}
