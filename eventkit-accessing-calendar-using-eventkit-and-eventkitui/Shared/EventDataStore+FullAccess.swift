/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Manages full-access eventkit interactions.
*/

import EventKit

extension EventDataStore {
    
    var isFullAccessAuthorized: Bool {
        if #available(iOS 17.0, *) {
            EKEventStore.authorizationStatus(for: .event) == .fullAccess
        } else {
            // Fall back on earlier versions.
            EKEventStore.authorizationStatus(for: .event) == .authorized
        }
    }

    /// Prompts the user for full-access authorization to Calendar.
    private func requestFullAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            return try await eventStore.requestFullAccessToEvents()
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
            return try await requestFullAccess()
        case .restricted:
            throw EventStoreError.restricted
        case .denied:
            throw EventStoreError.denied
        case .fullAccess:
            return true
        case .writeOnly:
            throw EventStoreError.upgrade
        @unknown default:
            throw EventStoreError.unknown
        }
    }
    
    /// Fetches all events occuring within a month in all the user's calendars.
    func fetchEvents() -> [EKEvent] {
        guard isFullAccessAuthorized else { return [] }
        let start = Date.now
        let end = start.oneMonthOut
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate).sortedEventByAscendingDate()
    }
    
    /// Removes an event.
    private func removeEvent(_ event: EKEvent) throws {
        try self.eventStore.remove(event, span: .thisEvent, commit: false)
    }
    
    /// Batches all the remove operations.
    func removeEvents(_ events: [EKEvent]) throws {
        do {
            try events.forEach { event in
                try removeEvent(event)
            }
            try eventStore.commit()
         } catch {
             eventStore.reset()
             throw error
         }
    }
}
