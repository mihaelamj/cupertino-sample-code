/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Symbols used on card faces.
*/

import Foundation
import SwiftUI

enum Symbol: String, RawRepresentable, CaseIterable {
    
    case flame = "flame.fill"
    case drop = "drop.fill"
    case bolt = "bolt.fill"
    case hare = "hare.fill"
    case tortoise = "tortoise.fill"
    case pawprint = "pawprint.fill"
    case ant = "ant.fill"
    case ladybug = "ladybug.fill"
    case leaf = "leaf.fill"
    case heart = "heart.fill"
    case eye = "eye.fill"
    case facemask = "facemask.fill"
    case bandage = "bandage.fill"
    case cross = "cross.case.fill"
    case bed = "bed.double.fill"
    case lungs = "lungs.fill"
    case pills = "pills.fill"
    case ear = "ear.fill"
    case waveform = "waveform.path.ecg.rectangle.fill"
    case staroflife = "staroflife.fill"
    case freeMatch = "star.circle.fill"
    case inactive = "star.fill"
    
    static func randomSymbol() -> Symbol {
        var result: Symbol = .flame
        
        while let symbol = Symbol.allCases.randomElement(),
              symbol != .inactive,
              symbol != .freeMatch {
            result = symbol
        }
        
        return result
    }
    
    static func symbolSet(numberOfPairs: Int) -> [Symbol] { [Int](0..<numberOfPairs).map { _ in randomSymbol() } }
    
    var symbolName: String { rawValue }
    
    var color: Color {
        switch self {
        case .flame:
            return Color.red
        case .drop:
            return Color.blue
        case .bolt:
            return Color.yellow
        case .hare:
            return Color.gray
        case .tortoise:
            return Color.mint
        case .pawprint:
            return Color.brown
        case .ant:
            return Color.black
        case .ladybug:
            return Color.pink
        case .leaf:
            return Color.green
        case .heart:
            return Color.purple
        case .eye:
            return Color.cyan
        case .facemask:
            return Color.indigo
        case .bandage:
            return Color.orange
        case .cross:
            return Color.teal
        case .bed:
            return Color(UIColor.magenta)
        case .lungs:
            return Color.indigo
        case .pills:
            return Color(#colorLiteral(red: 0.1414394081, green: 0.5119228959, blue: 0.9287025332, alpha: 1))
        case .ear:
            return Color.brown
        case .waveform:
            return Color(#colorLiteral(red: 0, green: 1, blue: 0.7481563687, alpha: 1))
        case .staroflife:
            return Color(#colorLiteral(red: 0.917560339, green: 0.80871737, blue: 0.272224009, alpha: 1))
        case .freeMatch:
            return Color(uiColor: UIColor.clear)
        case .inactive:
            return Color.black
        }
    }
    
    var foregroundColor: Color {
        if self == .freeMatch {
            return Color.black
        }
        return Color.white
    }
    
    var accessibilityLabel: String {
        switch self {
        case .flame:
            return "Flame"
        case .drop:
            return "Drop"
        case .bolt:
            return "Bolt"
        case .hare:
            return "Hare"
        case .tortoise:
            return "Tortoise"
        case .pawprint:
            return "Pawprint"
        case .ant:
            return "Ant"
        case .ladybug:
            return "Ladybug"
        case .leaf:
            return "Leaf"
        case .heart:
            return "Heart"
        case .eye:
            return "Eye"
        case .facemask:
            return "Facemask"
        case .bandage:
            return "Bandage"
        case .cross:
            return "Cross"
        case .bed:
            return "Bed"
        case .lungs:
            return "Lungs"
        case .pills:
            return "Pills"
        case .ear:
            return "Ear"
        case .waveform:
            return "Waveform"
        case .staroflife:
            return "Star Of Life"
        case .freeMatch:
            return "Free Match"
        case .inactive:
            return "Inactive"
        }
    }
}
