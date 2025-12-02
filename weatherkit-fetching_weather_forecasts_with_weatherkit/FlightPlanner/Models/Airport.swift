/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model that represents an airport.
*/

import Foundation
import CoreLocation

struct Airport: Hashable, Identifiable {
    var code: String
    var name: String
    var city: String
    var region: String
    var country: String
    var elevation: Double
    var latitude: Double
    var longitude: Double
    
    var id: String { code }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    var locationDescription: String {
        "\(city), \(country) (\(code))"
    }
    
    var imageName: String {
        Airport.randomImageName(for: self)
    }
}

extension Airport: Codable {
    enum CodingKeys: String, CodingKey {
        case code
        case name
        case city
        case region
        case country
        case elevation
        case latitude = "lat"
        case longitude = "lon"
    }
}

extension Airport: Comparable {
    static func <(lhs: Airport, rhs: Airport) -> Bool {
        lhs.name < rhs.name
    }
}

extension Airport {
    fileprivate static func randomImageName(for airport: Airport) -> String {
        let imageNames = [
            "City_11_Glass_Skyscrapers",
            "City_13_Civic_Center",
            "City_6_Modern_Building",
            "Landscape_1_Vineyard",
            "Landscape_21_Rainbow",
            "Landscape_22_Sailboats",
            "Landscape_25_Tropical_Sunset_Palms",
            "Landscape_29_Tropical_Sunset_Boat"
        ]
        let sum = airport.elevation + airport.latitude + airport.longitude
        let seed = airport.hashValue + Int(sum)
        var generator = SeededRandomNumberGenerator(seed: seed)
        return imageNames.randomElement(using: &generator)!
    }
    
    private struct SeededRandomNumberGenerator: RandomNumberGenerator {
        init(seed: Int) {
            srand48(seed)
        }

        func next() -> UInt64 {
            UInt64(drand48() * Double(UInt64.max))
        }
    }
}

#if DEBUG
// Use this for preview data.
extension Airport {
    static var all: [Airport] {
        let path = Bundle.main.path(forResource: "Airports", ofType: "json")!
        let fileURL = URL(fileURLWithPath: path)
        let data = try! Data(contentsOf: fileURL, options: .mappedIfSafe)
        return try! JSONDecoder().decode([Airport].self, from: data)
    }
    
    static var mia: Airport {
        all.first(where: { $0.code == "MIA" })!
    }
    
    static var pmi: Airport {
        all.first(where: { $0.code == "PMI" })!
    }
    
    static var sfo: Airport {
        all.first(where: { $0.code == "SFO" })!
    }
}

extension Sequence where Element == Airport {
    static var all: [Airport] {
        Airport.all
    }
}
#endif
