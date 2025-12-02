/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A file containing extensions for saving data from app models to HealthKit.
*/

import Foundation
import HealthKit
import SwiftUI

extension HKHealthStore {
    /// Saves a State of Mind sample from an event.
    func saveStateOfMindSample(event: EventModel, emoji: EmojiType) async throws {
        /// Create a State of Mind sample for a date and State of Mind association.
        let sample = HKStateOfMind(date: event.endDate,
                                   kind: .momentaryEmotion,
                                   valence: emoji.valence,
                                   labels: [emoji.label],
                                   associations: [event.association])
        try await save(sample)
    }
}

