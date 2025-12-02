/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An enumeration of badges that people can earn by completing activities at a landmark.
*/

import SwiftUI

/// An enumeration of badges that people can earn by completing activities at a landmark.
enum Badge: String, Identifiable, CaseIterable {
    case greatBarrierReef
    case niagaraFalls
    case saharaDesert
    case mountFuji
    case amazonRainforest
    case southShetlandIslands
    case rockyMountains
    
    var id: String {
        return self.rawValue
    }

    var badgeName: LocalizedStringResource {
        switch self {
        case .greatBarrierReef: LocalizedStringResource("Great Barrier Reef", table: "LandmarkData")
        case .niagaraFalls: LocalizedStringResource("Niagara Falls", table: "LandmarkData")
        case .saharaDesert: LocalizedStringResource("Sahara Desert", table: "LandmarkData")
        case .mountFuji: LocalizedStringResource("Mount Fuji", table: "LandmarkData")
        case .amazonRainforest: LocalizedStringResource("Amazon Rainforest", table: "LandmarkData")
        case .southShetlandIslands: LocalizedStringResource("South Shetland Islands", table: "LandmarkData")
        case .rockyMountains: LocalizedStringResource("Rocky Mountains", table: "LandmarkData")
        }
    }
    
    var symbolName: String {
        switch self {
        case .greatBarrierReef: "fish.fill"
        case .niagaraFalls: "ferry.fill"
        case .saharaDesert: "sun.max.fill"
        case .mountFuji: "mountain.2.fill"
        case .amazonRainforest: "bird.fill"
        case .southShetlandIslands: "snowflake"
        case .rockyMountains: "tree.fill"
        }
    }
    
    func fontSize(forEarnedView: Bool = false) -> Double {
        switch self {
        case .greatBarrierReef: forEarnedView ? 24.0 : 20.0
        case .niagaraFalls: forEarnedView ? 22.0 : 18.0
        case .saharaDesert: forEarnedView ? 30.0 : 26.0
        case .mountFuji: forEarnedView ? 22.0 : 18.0
        case .amazonRainforest: forEarnedView ? 22.0 : 18.0
        case .southShetlandIslands: forEarnedView ? 32.0 : 28.0
        case .rockyMountains: forEarnedView ? 22.0 : 18.0
        }
    }
    
    var badgeColor: Color {
        switch self {
        case .greatBarrierReef: .cyan
        case .niagaraFalls: .cyan
        case .saharaDesert: .orange
        case .mountFuji: .blue
        case .amazonRainforest: .green
        case .southShetlandIslands: .blue
        case .rockyMountains: .mint
        }
    }
}
