/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Emoji representing the severity of a symptom.
*/

import Foundation
import SwiftUI

/// An enumeration of the different levels of intensity for a symptom.
enum SymptomIntensity: Int, CaseIterable, Identifiable {
    var id: Self { self }

    case none = 0
    case mild = 1
    case moderate = 2
    case severe = 3
    case extreme = 4

    /// The emoji representation of the intensity.
    var emoji: String {
        switch self {
        case .none: return "😌"
        case .mild: return "😐"
        case .moderate: return "😕"
        case .severe: return "😡"
        case .extreme: return "🤯"
        }
    }

    var color: Color {
        switch self {
        case .none: Color.yellow
        case .mild: Color.green
        case .moderate: Color.teal
        case .severe: Color.indigo
        case .extreme: Color.red
        }
    }
}
