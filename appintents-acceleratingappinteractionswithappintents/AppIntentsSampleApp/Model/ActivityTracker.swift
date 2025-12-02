/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that keeps track of the specific activities someone does on a trail, such as a hike.
*/

import AppIntents
import Foundation
import HealthKit
import Observation
import OSLog

/// Manages recording of a person's activities on a trail, such as hiking.
@Observable class ActivityTracker: ActivityTrackingActions, @unchecked Sendable {
    static let shared = ActivityTracker()
    
    private let historyDataURL = URL.documentsDirectory.appending(path: "ActivityHistory.plist")
    
    private init() {
        do {
            let plistData = try Data(contentsOf: historyDataURL)
            let decoder = PropertyListDecoder()
            let history = try decoder.decode([Activity].self, from: plistData)
            activityHistory = history
            activityInProgress = history.first { $0.end == nil }
        } catch {
            activityHistory = []
        }
        
        isActivityTrackingAuthorized = true
        
    #if os(watchOS)
        liveWorkoutManager = LiveWorkoutManager()
        isActivityTrackingAuthorized = false
    #endif
    }
    
    private(set) var activityHistory: [Activity]
    
    /// The current activity a person is recording.
    private(set) var activityInProgress: Activity?
    
    /// The instructions for the next navigation step, such as the distance to the next turn.
    var nextManeuver: String?
    
    /// This is nil except in watchOS, where it records a workout into `HKHealthStore`.
    private var liveWorkoutManager: ActivityTrackingActions?

    /// This property is `true` unless it's running in watchOS, where it represents HealthKit authorization status.
    var isActivityTrackingAuthorized: Bool
    
    /// In watchOS, this presents a HealthKit authorization. For other platforms, it directly returns `isActivityTrackingAuthorized`.
    func requestActivityTrackingAuthorization() async throws -> Bool {
        if let liveResult = try await liveWorkoutManager?.requestActivityTrackingAuthorization() {
            isActivityTrackingAuthorized = liveResult
        }
        return isActivityTrackingAuthorized
    }
    
    /// Starts a new activity and adds it to the activity history.
    @MainActor
    func startNewActivity(_ activity: ActivityStyle, on trail: Trail) async throws {
        // Ends any other in-progress activity before starting a new activity.
        endActivity()
        
        Logger.activityTracking.debug("Starting to track a new activity")
        try await liveWorkoutManager?.startNewActivity(activity, on: trail)
        
        let newActivity = Activity(id: UUID(), style: activity, trail: trail.id, start: Date(), end: nil)
        activityInProgress = newActivity
        activityHistory.append(newActivity)
        saveHistory()
        
        do {
            /**
             Donating an intent for the Action button replaces the currently associated intent with the donated one. Use this technique to
             contextually change what the Action button does from any location in your code. When a donation occurs, the system
             may display UI informing the customer of the updated functionality for the Action button based on the donated intent.
             */
            try await StartTrailActivity()
                .donate(result: .result(actionButtonIntent: NextTrailManeuver()))
            Logger.activityTracking.debug("Configured the Action button")
        } catch {
            Logger.activityTracking.error("Unable to configure the Action button")
        }
    }

    @MainActor
    func pauseActivity() {
        guard activityInProgress != nil else { return }
        liveWorkoutManager?.pauseActivity()
        Logger.activityTracking.debug("Pausing activity")
    }

    @MainActor
    func resumeActivity() {
        guard activityInProgress != nil else { return }
        liveWorkoutManager?.resumeActivity()
        Logger.activityTracking.debug("Resuming activity")
    }

    /// Ends the new activity, updating the activity with the time it completes.
    @MainActor
    func endActivity() {
        guard let activityInProgress else { return }
        
        var completedActivity = activityInProgress
        completedActivity.end = Date()
        self.activityInProgress = nil
        nextManeuver = nil
        
        activityHistory.removeAll { $0.id == completedActivity.id }
        activityHistory.append(completedActivity)
        
        liveWorkoutManager?.endActivity()
        
        Logger.activityTracking.error("Ended activity")
    }
    
    /// - Returns: An array of activities related to a specific trail.
    func activityHistory(on trail: Trail.ID) -> [Activity] {
        activityHistory.filter { $0.trail == trail }
    }
    
    /// - Returns: A summary structure of all of the completed activities.
    var activityStatistics: ActivityStatisticsSummary {
        let stats = ActivityStatisticsSummary()
        stats.summaryStartDate = activityHistory.first?.start ?? Date()
        for activity in activityHistory {
            let trail = TrailDataManager.shared.trail(with: activity.trail)!
            stats.distanceTraveled.value += trail.trailLength.value
            stats.caloriesBurned.value += 100
        }
        stats.workoutsCompleted = activityHistory.count
        return stats
    }
    
    /// Saves the activity history to disk.
    private func saveHistory() {
        do {
            let coder = PropertyListEncoder()
            let data = try coder.encode(activityHistory)
            try data.write(to: historyDataURL)
            Logger.activityTracking.error("Saved activity history")
        } catch let error {
            Logger.activityTracking.error("Unable to save activity history. \(String(describing: error))")
        }
    }
}

#if os(watchOS)

/**
 `LiveWorkoutManager` provides a minimal implementation of tracking a live workout using HealthKit on Apple Watch to demonstrate
 how to use the Action button with App Intents. Consult the HealthKit documentation for detailed information on how to make a complete implementation
 for tracking workout sessions on Apple Watch.
 */
private class LiveWorkoutManager: NSObject, ActivityTrackingActions {
    
    /// This property has a value when a workout is in progress.
    private var currentWorkoutIdentifier: String?
    
    /// This property is `true` when a person grants HealthKit authorization.
    var isActivityTrackingAuthorized: Bool = false
    
    /// The data store containing a person's health data.
    private let healthStore = HKHealthStore()
    
    /// Controls the workout session state, such as start and pause states.
    private var session: HKWorkoutSession?
    
    /// Collects health data samples throughout the workout session.
    private var builder: HKLiveWorkoutBuilder?
    
    /// Requests authorization to write workout metrics to HealthKit for the workout.
    func requestActivityTrackingAuthorization() async throws -> Bool {
        let shareTypes: Set = [
            HKQuantityType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
        
        do {
            Logger.activityTracking.debug("Requesting HealthKit authorization")
            try await healthStore.requestAuthorization(toShare: shareTypes, read: [])
            isActivityTrackingAuthorized = true
        } catch let error {
            isActivityTrackingAuthorized = false
            Logger.activityTracking.error("Error requesting HealthKit authorization \(String(describing: error))")
            throw error
        }
        
        return isActivityTrackingAuthorized
    }
    
    /// Starts a new workout and adds it to HealthKit.
    func startNewActivity(_ activity: ActivityStyle, on trail: Trail) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = activity.workoutStyle
        configuration.locationType = .outdoor
        
        // Creates the workout session and obtains a workout builder to collect health data.
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch let error {
            Logger.activityTracking.error("Couldn't create the workout session. \(String(describing: error))")
            throw error
        }

        // Sets the builder's data source to the instance's `HKHealthStore` object.
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
        
        // Starts the workout session and begins data collection.
        let startDate = Date()
        session?.startActivity(with: startDate)
        
        do {
            try await builder?.beginCollection(at: startDate)
            currentWorkoutIdentifier = activity.rawValue
            Logger.activityTracking.debug("Workout started")
        } catch let error {
            Logger.activityTracking.error("The workout builder couldn't begin data collection. \(String(describing: error))")
            throw error
        }
    }
    
    func pauseActivity() {
        if currentWorkoutIdentifier != nil {
            session?.pause()
        }
    }
    
    func resumeActivity() {
        if currentWorkoutIdentifier != nil {
            session?.resume()
        }
    }
    
    /// Ends the workout session.
    func endActivity() {
        if currentWorkoutIdentifier != nil {
            session?.end()
            currentWorkoutIdentifier = nil
        }
    }
}

#endif // #if os(watchOS)

/**
 Defines an interface for both iOS and watchOS activity tracking, to separate the simple activity tracking in iOS from the
 live workout tracking APIs only available in watchOS with minimal `#if os(watchOS)` lines breaking up the code.
 */
@MainActor
private protocol ActivityTrackingActions {
    var isActivityTrackingAuthorized: Bool { get }
    func requestActivityTrackingAuthorization() async throws -> Bool
    
    func startNewActivity(_ activity: ActivityStyle, on trail: Trail) async throws
    func pauseActivity()
    func resumeActivity()
    func endActivity()
}
