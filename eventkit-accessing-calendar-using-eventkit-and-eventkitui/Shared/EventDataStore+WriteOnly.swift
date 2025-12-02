/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Manages write-only eventkit interactions.
*/

import EventKit

extension EventDataStore {
    /// Prompts the user for write-only authorization to Calendar.
    func requestWriteOnlyAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await eventStore.requestWriteOnlyAccessToEvents()
        } else {
            // Fall back on earlier versions.
            return try await eventStore.requestAccess(to: .event)
        }
    }
    
    /// Verifies the authorization status for the app.
    func verifyAuthorizationStatus() async throws -> Bool {
        let status = EKEventStore.authorizationStatus(for: .event)
        
        switch status {
        case .notDetermined:
            return try await requestWriteOnlyAccess()
        case .restricted:
            throw EventStoreError.restricted
        case .denied:
            throw EventStoreError.denied
        case .fullAccess:
            return true
        case .writeOnly:
            return true
        @unknown default:
            throw EventStoreError.unknown
        }
    }
    
    /// Create an event with the specified lesson details, then save it with all its occurences to the user's Calendar.
    func addLesson(_ lesson: Lesson, date: Date, calendar: EKCalendar? = nil) throws {
        let newEvent = lesson.eventWithDate(date, store: eventStore, calendar: calendar)
        try self.eventStore.save(newEvent, span: .futureEvents)
    }
}
