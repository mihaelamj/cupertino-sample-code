/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model that represents a flight leg---a flight operation within
 a flight segment from one airport to another.
*/

import Foundation

struct FlightLeg: Codable, Hashable, Identifiable, Sendable {
    let designator: String
    var color: FlightSegment.Color
    var gate: String
    var origin: Airport
    var destination: Airport
    var departure: Date
    var arrival: Date
    
    var duration: TimeInterval {
        arrival.timeIntervalSince(departure)
    }
    
    var id: String { designator }
    
    init(
        designator: String = FlightLeg.randomDesignator(),
        color: FlightSegment.Color = .random,
        gate: String = FlightLeg.randomGate(),
        origin: Airport,
        destination: Airport,
        departure: Date,
        arrival: Date
    ) {
        self.designator = designator
        self.color = color
        self.gate = gate
        self.origin = origin
        self.destination = destination
        self.departure = departure
        self.arrival = arrival
    }
     
    private static func randomDesignator() -> String {
        let int = Int.random(in: 1...9999)
        return String(format: "EX %04d", int)
    }
    
    private static func randomGate() -> String {
        let letters = "ABCDEFG"
        let int = Int.random(in: 1...24)
        return "\(letters.randomElement()!)\(int)"
    }
}

extension FlightLeg: Comparable {
    static func <(lhs: FlightLeg, rhs: FlightLeg) -> Bool {
        if lhs.departure < rhs.departure {
            return true
        } else if lhs.departure == rhs.departure {
            return lhs.arrival < rhs.arrival
        } else {
            return false
        }
    }
}

#if DEBUG
// Use this for preview data.
extension FlightLeg {
    static var sfoToMia: FlightLeg {
        FlightLeg(
            origin: .sfo,
            destination: .mia,
            departure: .now,
            arrival: .now.addingTimeInterval(60 * 60 * 6)) // +6 hours
    }
    
    static var miaToPmi: FlightLeg {
        FlightLeg(
            origin: .mia,
            destination: .pmi,
            departure: .now,
            arrival: .now.addingTimeInterval(60 * 60 * 6)) // +6 hours
    }
}
#endif
