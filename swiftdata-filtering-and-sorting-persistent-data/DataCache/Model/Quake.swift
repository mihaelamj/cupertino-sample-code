/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A representation of an earthquake.
*/

import SwiftUI
import SwiftData

/// A representation of an earthquake.
@Model
class Quake {
    /// A unique identifier associated with each earthquake event.
    @Attribute(.unique) var code: String

    /// The measured strength of the earthquake.
    var magnitude: Double

    /// When the earthquake happened.
    var time: Date

    /// Where the earthquake happened.
    var location: Location

    /// Creates a new earthquake from the specified values.
    init(
        code: String,
        magnitude: Double,
        time: Date,
        name: String,
        longitude: Double,
        latitude: Double
    ) {
        self.code = code
        self.magnitude = magnitude
        self.time = time
        self.location = Location(name: name, longitude: longitude, latitude: latitude)
    }
}

// A convenience for accessing a quake in an array by its identifier.
extension Array where Element: Quake {
    /// Gets the first quake in the array with the specified ID, if any.
    subscript(id: Quake.ID?) -> Quake? {
        first { $0.id == id }
    }
}

// Values that the app uses to represent earthquakes in the interface.
extension Quake {
    /// A color that represents the quake's magnitude.
    var color: Color {
        switch magnitude {
        case 0..<1:
            return .green
        case 1..<2:
            return .yellow
        case 2..<3:
            return .orange
        case 3..<5:
            return .red
        case 5..<7:
            return .purple
        case 7..<Double.greatestFiniteMagnitude:
            return .indigo
        default:
            return .gray
        }
    }

    /// The size for a marker that represents a quake on a map.
    var markerSize: CGSize {
        let value = (magnitude + 3) * 6
        return CGSize(width: value, height: value)
    }

    /// The earthquakes magnitude, to one decimal place.
    var magnitudeString: String {
        magnitude.formatted(.number.precision(.fractionLength(1)))
    }

    /// A complete representation of the event's date.
    var fullDate: String {
        time.formatted(date: .complete, time: .complete)
    }
}

// A string represenation of the quake.
extension Quake: CustomStringConvertible {
    var description: String {
        "\(fullDate) \(magnitudeString) \(location)"
    }
}

extension Quake {
    /// A filter that checks for a date and text in the quake's location name.
    static func predicate(
        searchText: String,
        searchDate: Date
    ) -> Predicate<Quake> {
        let calendar = Calendar.autoupdatingCurrent
        let start = calendar.startOfDay(for: searchDate)
        let end = calendar.date(byAdding: .init(day: 1), to: start) ?? start

        return #Predicate<Quake> { quake in
            (searchText.isEmpty || quake.location.name.contains(searchText))
            &&
            (quake.time > start && quake.time < end)
        }
    }

    /// Report the range of dates over which there are earthquakes.
    static func dateRange(modelContext: ModelContext) -> ClosedRange<Date> {
        let descriptor = FetchDescriptor<Quake>(sortBy: [.init(\.time, order: .forward)])
        guard let quakes = try? modelContext.fetch(descriptor),
              let first = quakes.first?.time,
              let last = quakes.last?.time else { return .distantPast ... .distantFuture }
        return first ... last
    }

    /// Reports the total number of quakes.
    static func totalQuakes(modelContext: ModelContext) -> Int {
        (try? modelContext.fetchCount(FetchDescriptor<Quake>())) ?? 0
    }
}

// Ensure that the model's conformance to Identifiable is public.
extension Quake: Identifiable {}
