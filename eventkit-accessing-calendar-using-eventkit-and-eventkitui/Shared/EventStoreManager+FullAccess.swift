/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for the app.
*/

import EventKit

extension EventStoreManager {
    /*
        Listens for event store changes, which are always posted on the main thread. When the app receives a full access authorization status, it
        fetches all events occuring within a month in all the user's calendars.
    */
    func listenForCalendarChanges() async {
        let center = NotificationCenter.default
        let notifications = center.notifications(named: .EKEventStoreChanged).map({ (notification: Notification) in notification.name })
        
        for await _ in notifications {
            guard await dataStore.isFullAccessAuthorized else { return }
            await self.fetchLatestEvents()
        }
    }
    
    func setupEventStore() async throws {
        let response = try await dataStore.verifyAuthorizationStatus()
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        if response {
            await fetchLatestEvents()
        }
    }
    
  func fetchLatestEvents() async {
        let latestEvents = await dataStore.fetchEvents()
        self.events = latestEvents
   }
    
    func removeEvents(_ events: [EKEvent]) async throws {
        try await dataStore.removeEvents(events)
    }
}
