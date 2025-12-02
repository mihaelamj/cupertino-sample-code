/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Manages reading and writing reminder data from the event store.
*/

import OSLog
import EventKit
import MapKit

enum ReminderStoreError: Error {
    case missingCalendar
    case missingReminder(message: String)
    case missingSource(message: String)
}

extension ReminderStoreError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingCalendar: "No default list for reminders on this device."
        case .missingReminder(message: let message): "Failed to find reminder with identifier: \(message)."
        case .missingSource(message: let message): "Failed to find source with identifier: \(message)."
        }
    }
}

actor ReminderStore {
    let eventStore: EKEventStore
    
    var containsDefaultList: Bool {
        eventStore.defaultCalendarForNewReminders() != nil
    }
    
    var allSources: [SourceModel] {
        return eventStore.sources
            .map { SourceModel(source: $0) }
    }
    
    init() {
        // Initialize the event store.
        self.eventStore = EKEventStore()
    }
    
    /// Prompts the person for full access authorization to reminder data.
    func requestAccess() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            eventStore.requestFullAccessToReminders { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                }
                continuation.resume(returning: granted)
            }
        }
    }
    
    /// Fetches the default list for reminders.
    private func defaultList() throws -> EKCalendar {
        guard let list = eventStore.defaultCalendarForNewReminders() else {
            throw ReminderStoreError.missingCalendar
        }
        return list
    }
}

extension ReminderStore {
    /// Initializes a non-floating reminder with title, priority, due date components, and time zone.
    private func createReminder(with entry: LocationReminderEntry) throws -> EKReminder {
        let calendar = try defaultList()
        
        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = calendar
        reminder.title = entry.title
        reminder.priority = entry.priority
        
        /*
            The app creates reminders with a specific date and time. To create an
            all-day reminder, set `dueDateComponents` to a date component without
            hour, minute, and second components.
        */
        reminder.dueDateComponents = Date.next7DaysComponents
        
        /*
            A floating reminder is one that isn't associated with a specific time
            zone. Set `timeZone` to `nil` if you wish to have a floating reminder.
        */
        reminder.timeZone = TimeZone.current
        return reminder
    }
    
    /// Creates a location reminder with the specified map annotation.
    func save(_ entry: LocationReminderEntry, annotation: MapAnnotation) throws {
        let reminder = try createReminder(with: entry)
        
        let structuredLocation = EKStructuredLocation(title: annotation.name)
        structuredLocation.geoLocation = CLLocation(latitude: annotation.coordinates.latitude, longitude: annotation.coordinates.longitude)
        
        /*
            The structured location object expects a value defined in meters for its `radius` property.
            The app displays the radius's value in the person’s current preferences for unit of length measurement.
            If the person’s current preferences is a unit other than meters, convert the value of `entry.radius`
            to meters before assigning it to `radius`.
         */
        // Get the person's preferred unit of length measurement.
        let preferredUnit = UnitLength(forLocale: .current, usage: .asProvided)
        structuredLocation.radius = (preferredUnit == .meters) ? entry.radius : entry.radius.convert(from: preferredUnit, to: .meters)
        
        let alarm = EKAlarm(relativeOffset: 0)
        alarm.structuredLocation = structuredLocation
        alarm.proximity = entry.proximity
        
        reminder.addAlarm(alarm)
        
        try eventStore.save(reminder, commit: true)
    }
    
    /// Creates a location reminder with the specified location and address.
    func save(_ entry: LocationReminderEntry, location: CLLocation, address: String) throws {
        let reminder = try createReminder(with: entry)
        
        let mapAddress = MKAddress(fullAddress: address, shortAddress: nil)
        let mapItem = MKMapItem(location: location, address: mapAddress)
        
        let structuredLocation = EKStructuredLocation(mapItem: mapItem)
        
        let preferredUnit = UnitLength(forLocale: .current, usage: .asProvided)
        structuredLocation.radius = (preferredUnit == .meters) ? entry.radius : entry.radius.convert(from: preferredUnit, to: .meters)
        
        let alarm = EKAlarm(relativeOffset: 0)
        alarm.structuredLocation = structuredLocation
        alarm.proximity = entry.proximity
        
        reminder.addAlarm(alarm)
        try eventStore.save(reminder, commit: true)
    }
    
    /// Creates a list with specified name in the source with the given source identifier.
    func saveList(with name: String, inSourceWithIdentifier identifier: String) throws {
        guard let source = eventStore.source(withIdentifier: identifier) else {
            throw ReminderStoreError.missingSource(message: identifier)
        }
        
        let list = EKCalendar(for: .reminder, eventStore: eventStore)
        list.title = name
        list.source = source
        try eventStore.saveCalendar(list, commit: true)
    }
}

extension ReminderStore {
    /// Locates a `EKreminder` object matching the specified location reminder.
    private func ekReminder(for locationReminder: LocationReminder) async throws -> EKReminder {
        guard let match = eventStore.calendarItem(withIdentifier: locationReminder.calendarIdentifer),
              let eKReminder = match as? EKReminder else {
            throw ReminderStoreError.missingReminder(message: locationReminder.calendarIdentifer)
        }
        return eKReminder
    }
    
    /// Fetches all location--based reminders from all the person's lists.
    func fetchReminders() async -> [LocationReminder] {
        let predicate = eventStore.predicateForReminders(in: nil)
        
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                var result: [LocationReminder] = []
                
                if let reminders {
                    result = reminders
                        .filter(\.isLocation)
                        .map { LocationReminder(reminder: $0) }
                }
                continuation.resume(returning: result)
            }
        }
    }
}

extension ReminderStore {
    /// Completes the specified location reminder.
    func completeLocationReminder(_ locationReminder: LocationReminder) async throws {
        let ekReminder = try await ekReminder(for: locationReminder)
        ekReminder.isCompleted.toggle()
        try eventStore.save(ekReminder, commit: true)
    }
}

extension ReminderStore {
    /// Removes a location reminder from the event store..
    private func removeLocationReminder(_ locationReminder: LocationReminder) async throws {
        let ekReminder = try await ekReminder(for: locationReminder)
        try eventStore.remove(ekReminder, commit: false)
    }
    
    /// Batches all the remove operations.
    func removeLocationReminders(_ locationReminders: [LocationReminder]) async throws {
        do {
            for locationReminder in locationReminders {
                try await removeLocationReminder(locationReminder)
            }
            try eventStore.commit()
        } catch {
            eventStore.reset()
            throw error
        }
    }
}
