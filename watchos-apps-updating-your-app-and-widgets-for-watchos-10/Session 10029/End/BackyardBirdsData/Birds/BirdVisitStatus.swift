/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The bird visit status.
*/

import Foundation

public enum BirdVisitStatus {
    case never
    case recently(Date)
}

// MARK: - Localized title

public extension BirdVisitStatus {
    var title: String {
        switch self {
        case .never:
            return String(
                localized: "Not yet seen",
                table: "Birds",
                bundle: .module,
                comment: "A phrase indicating that a bird has never visited a backyard."
            )
        case .recently(let date):
            let timeInterval = -date.timeIntervalSinceNow
            let duration = Duration(secondsComponent: Int64(timeInterval), attosecondsComponent: 0)
            let shorthand = duration.formatted(.units(allowed: [.days, .hours, .minutes, .seconds], width: .abbreviated, maximumUnitCount: 1))
            return String(
                localized: "Seen \(shorthand) ago",
                table: "Birds",
                bundle: .module,
                comment: """
                    The first variable is a shorthand formatted duration, such as 4d, 30m, or 20s.
                    The first variable is a shorthand formatted duration. For example, 4d, 30m, or 20s.
                    """
            )
        }
    }
}
