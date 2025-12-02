/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for the app.
*/

import EventKit
import Foundation

extension EventStoreManager {
    
    var store: EKEventStore {
         dataStore.eventStore
    }
    
    func setupEventStore() async throws {
        _ = try await dataStore.verifyAuthorizationStatus()
       authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
    
    func saveLesson(_ lesson: Lesson, date: Date, calendar: EKCalendar? = nil) async throws {
        try await dataStore.addLesson(lesson, date: date, calendar: calendar)
    }
}
