/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Settings for the configuration panel.
*/

import SwiftUI

struct DebugSettings {
    // Switch this to `true` to see the debug settings.
    let showOrnament = false

    // Timeline options.
    var controlsMovesToFrontWhenSnapped: Bool = true
    var ornamentSceneAnchorOverride: UnitPoint3D? = nil
    var ornamentContentAlignmentOverride: Alignment3D? = nil

    var toolbarBreakthroughEffectOption: BreakthroughOption = .subtle
    var popoverBreakthroughEffectOption: PopoverBreakthroughOption = .subtlePlusOpacity

    enum BreakthroughOption {
        case subtle
        case prominent
        case none
        
        var breakthroughEffect: BreakthroughEffect {
            switch self {
            case .subtle:
                return BreakthroughEffect.subtle
            case .prominent:
                return BreakthroughEffect.prominent
            case .none:
                return BreakthroughEffect.none
            }
        }
    }

    enum PopoverBreakthroughOption {
        case subtle
        case subtlePlusOpacity
        case prominent
        case none

        var breakthroughEffect: BreakthroughEffect {
            switch self {
            case .subtle, .subtlePlusOpacity:
                return BreakthroughEffect.subtle
            case .prominent:
                return BreakthroughEffect.prominent
            case .none:
                return BreakthroughEffect.none
            }
        }
    }

}
