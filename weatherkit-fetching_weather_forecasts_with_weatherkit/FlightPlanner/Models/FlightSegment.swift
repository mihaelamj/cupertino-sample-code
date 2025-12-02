/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model that represents a flight segment---a flight operation with
 a single flight designator between the initial origin airport where passengers
 first board an aircraft and their final destination.
*/

import Foundation
import SwiftUI

struct FlightSegment: Codable, Hashable, Identifiable, Sendable {
    let id: UUID
    var legs: [FlightLeg]
    
    init?(id: UUID = UUID(), legs: [FlightLeg]) {
        guard !legs.isEmpty else {
            return nil
        }
        self.id = id
        self.legs = legs
    }
    
    /// The initial origin airport, based on the first flight leg of the segment.
    var origin: Airport {
        firstLeg.origin
    }
    
    /// The final destination airport, based on the last flight leg of the segment.
    var destination: Airport {
        legs[legs.count - 1].destination
    }
    
    /// The initial departure date, based on the first flight leg of the segment.
    var departure: Date {
        firstLeg.departure
    }
    
    /// The final arrival date, based on the last flight leg of the segment.
    var arrival: Date {
        lastLeg.arrival
    }
    
    /// The duration for the flight segment, from initial origin airport to the final destination.
    var duration: TimeInterval {
        legs.reduce(0) { partialResult, leg in
            partialResult + leg.duration
        }
    }
    
    private var firstLeg: FlightLeg {
        legs[0]
    }
    
    private var lastLeg: FlightLeg {
        legs[legs.count - 1]
    }
}

extension FlightSegment: Comparable {
    static func <(lhs: FlightSegment, rhs: FlightSegment) -> Bool {
        if lhs.departure < rhs.departure {
            return true
        } else if lhs.departure == rhs.departure {
            return lhs.arrival < rhs.arrival
        } else {
            return false
        }
    }
}

extension FlightSegment {
    struct Color: Codable, Hashable {
        var hue: Double
        var saturation: Double
        var brightness: Double
    }
}

extension FlightSegment.Color {
    static var random: FlightSegment.Color {
        FlightSegment.Color(
            hue: randomHue(),
            saturation: 1,
            brightness: randomBrightness())
    }
    
    private static func randomHue() -> Double {
        .random(in: 0...255) / 256
    }
    
    private static func randomBrightness() -> Double {
        .random(in: 128...255) / 256
    }
}

extension Color {
    init(_ color: FlightSegment.Color) {
        self.init(
            hue: color.hue,
            saturation: color.saturation,
            brightness: color.brightness)
    }
}

#if DEBUG
// Use this for preview data.
extension FlightSegment {
    @MainActor
    static var sfoToMia: FlightSegment {
        FlightSegment(legs: [.sfoToMia])!
    }
    
    @MainActor
    static var sfoToMiaToPmi: FlightSegment {
        FlightSegment(legs: [.sfoToMia, .miaToPmi])!
    }
}
#endif
