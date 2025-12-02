/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An actor that provides an in-memory model container for previews.
*/

import SwiftData
import SwiftUI

/// An actor that provides an in-memory model container for previews.
actor PreviewSampleData {
    @MainActor
    static var container: ModelContainer = {
        return try! inMemoryContainer()
    }()

    static var inMemoryContainer: () throws -> ModelContainer = {
        let schema = Schema([Quake.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let sampleData: [any PersistentModel] = [
            Quake.xxsmall,
            Quake.xsmall,
            Quake.small,
            Quake.medium,
            Quake.large,
            Quake.xlarge,
            Quake.xxlarge,
            Quake.xxxlarge
        ]
        Task { @MainActor in
            sampleData.forEach {
                container.mainContext.insert($0)
            }
        }
        return container
    }
}

// Default quakes for use in previews.
extension Quake {
    static var xxsmall: Quake {
        .init(code: "1", magnitude: 0.5, time: .now, name: "West of California", longitude: -125, latitude: 35)
    }
    static var xsmall: Quake {
        .init(code: "2", magnitude: 1.5, time: .now, name: "West of California", longitude: -125, latitude: 35)
    }
    static var small: Quake {
        .init(code: "3", magnitude: 2.5, time: .now, name: "West of California", longitude: -125, latitude: 35)
    }
    static var medium: Quake {
        .init(code: "4", magnitude: 3.5, time: .now, name: "West of California", longitude: -125, latitude: 35)
    }
    static var large: Quake {
        .init(code: "5", magnitude: 4.5, time: .now, name: "West of California", longitude: -125, latitude: 35)
    }
    static var xlarge: Quake {
        .init(code: "6", magnitude: 5.5, time: .now, name: "West of California", longitude: -125, latitude: 35)
    }
    static var xxlarge: Quake {
        .init(code: "7", magnitude: 6.5, time: .now, name: "West of California", longitude: -125, latitude: 35)
    }
    static var xxxlarge: Quake {
        .init(code: "8", magnitude: 7.5, time: .now, name: "West of California", longitude: -125, latitude: 35)
    }
}

extension ViewModel {
    static var preview: ViewModel {
        let model = ViewModel()
        model.totalQuakes = 8
        return model
    }
}
