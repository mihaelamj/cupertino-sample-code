/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for the app.
*/

import EventKit
import MapKit
import OSLog

enum ReminderStoreManagerError: Error {
    case missingSource(String)
}

extension ReminderStoreManagerError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingSource(let message): "Failed to find source with identifier: \(message)."
        }
    }
}

@MainActor
@Observable class ReminderStoreManager {
    private let dataStore: ReminderStore
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "ReminderStoreManager")
    
    /// Specifies the authorization status for the app.
    var authorizationStatus: EKAuthorizationStatus
    
    /// Specifies whether the default list for adding reminders exists.
    var defaultListExists: Bool
    var sources: [SourceModel]
    var locationReminders: [LocationReminder]
    
    init(dataStore: ReminderStore = ReminderStore()) {
        self.dataStore = dataStore
        
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
        
        self.defaultListExists = false
        self.sources = []
        self.locationReminders = []
    }
    
    /*
        Listens for event store changes, which are always posted on the main thread.
        The app fetches all location-based reminders if the app has a full access authorization status.
    */
    func listenForCalendarChanges() async {
        let center = NotificationCenter.default
        let notifications = center.notifications(named: .EKEventStoreChanged).map({ $0.name })
        
        for await _ in notifications {
            await checkDefaultListExists()
            await fetchLatestReminders()
        }
    }
    
    func setupEventStore() async {
        do {
            let response = try await dataStore.requestAccess()
            
            authorizationStatus = EKEventStore.authorizationStatus(for: .reminder)
            
            if response {
                await checkDefaultListExists()
            }
        } catch {
            logger.error("Failed to request access to reminders: \(error)")
        }
    }
    
    /// Verifies the existence of a default list for saving reminders.
    func checkDefaultListExists() async {
        guard authorizationStatus == .fullAccess else { return }
        
        let response = await dataStore.containsDefaultList
        defaultListExists = response
        
        await fetchLatestSources()
    }
}

extension ReminderStoreManager {
    func add(_ entry: LocationReminderEntry, annotation: MapAnnotation) async {
        do {
            try await dataStore.save(entry, annotation: annotation)
        } catch {
            logger.error("Error adding location reminder with map annotation: \(error)")
        }
    }
    
    func add(_ entry: LocationReminderEntry, location: CLLocation) async {
        do {
            // Look up the address associated with `location`.
            let lookupLocationAddress = await location.reversedGeocodedLocation()

            try await dataStore.save(entry, location: location, address: lookupLocationAddress)
        } catch {
            logger.error( "Error adding location reminder with location: \(error)")
        }
    }
    
    func addList(with name: String, inSourceWithID id: SourceModel.ID) async {
        do {
            let source = try source(with: id)
            try await dataStore.saveList(with: name, inSourceWithIdentifier: source.sourceIdentifier)
        } catch {
            logger.error("Error adding list: \(error)")
        }
    }
}

extension ReminderStoreManager {
    func fetchLatestSources() async {
        guard authorizationStatus == .fullAccess else { return }
        
        if !defaultListExists {
            let latestSources = await dataStore.allSources
            sources = latestSources
        }
    }
    
    func fetchLatestReminders() async {
        guard authorizationStatus == .fullAccess else { return }
        
        let latestReminders = await dataStore.fetchReminders()
        locationReminders = latestReminders
    }
    
    /// Finds the source  model with the given identifier.
    private func source(with id: SourceModel.ID) throws -> SourceModel {
        guard let result = sources.first(where: { $0.id == id }) else {
            throw ReminderStoreManagerError.missingSource(id)
        }
        return result
    }
}

extension ReminderStoreManager {
    func completeLocationReminder(_ locationRemider: LocationReminder) async {
        do {
            try await dataStore.completeLocationReminder(locationRemider)
        } catch {
            logger.error("Error completing reminder: \(error)")
        }
    }
}

extension ReminderStoreManager {
    func removeLocationReminders(_ locationRemiders: [LocationReminder]) async {
        do {
            try await dataStore.removeLocationReminders(locationRemiders)
        } catch {
            logger.error( "Error removing reminders: \(error)")
        }
    }
}
