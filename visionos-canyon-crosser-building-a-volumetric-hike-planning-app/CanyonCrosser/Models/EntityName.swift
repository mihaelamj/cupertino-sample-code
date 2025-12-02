/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Names of entities to load into the app.
*/

import SwiftUI

enum EntityName: String {
    case locationIndicator = "location_indicator_mov_loc"
    case hikerWalking = "walking_mov_loc"
    case hikerStanding = "standing_mov_loc"
    case hikerSitting = "sitting_mov_loc"
    
    // Entities loaded in `prepareAssets()`.
    case grandCanyonScene = "GrandCanyon"
    case hiker = "anim_hikers_e"
    case clouds = "CloudsGroup"
    case birds = "anim_bird_a_loop"
    case sunlight = "EarthRotate"
    case terrain = "Terrain"
    case grandCanyonEntity = "CanyonTransform"
}
