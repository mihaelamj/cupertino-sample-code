/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An enumeration of app icons the app displays.
*/

import SwiftUI

/*
   The alternate app icons available for this app to use. These raw values match the names in the app's project settings
   under `ASSETCATALOG_COMPILER_APPICON_NAME` and `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`.
*/
enum Icon: String, CaseIterable, Identifiable {
    case primary    = "AppIcon"
    case blue       = "AppIcon-Blue"
    case green      = "AppIcon-Green"
    case orange     = "AppIcon-Orange"
    case purple     = "AppIcon-Purple"
    case pink       = "AppIcon-Pink"
    case teal       = "AppIcon-Teal"
    case yellow     = "AppIcon-Yellow"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .primary: .gray
        case .blue: .blue
        case .green: .green
        case .orange: .orange
        case .purple: .purple
        case .pink: .pink
        case .teal: .teal
        case .yellow: .yellow
        }
    }
}
