/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that wraps workout operations specific to iOS.
*/

import Foundation
import os
import HealthKit

// MARK: - Workout session management
//
extension WorkoutManager {
    func startWatchWorkout(workoutType: HKWorkoutActivityType) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .outdoor
        try await healthStore.startWatchApp(toHandle: configuration)
    }
    
    func retrieveRemoteSession() {
        /**
         HealthKit calls this handler when a session starts mirroring.
         */
        healthStore.workoutSessionMirroringStartHandler = { mirroredSession in
            Task { @MainActor in
                self.resetWorkout()
                self.session = mirroredSession
                self.session?.delegate = self
                Logger.shared.log("Start mirroring remote session: \(mirroredSession)")
            }
        }
    }
    
    func handleReceivedData(_ data: Data) throws {
        if let elapsedTime = try? JSONDecoder().decode(WorkoutElapsedTime.self, from: data) {
            var currentElapsedTime: TimeInterval = 0
            if session?.state == .running {
                currentElapsedTime = elapsedTime.timeInterval + Date().timeIntervalSince(elapsedTime.date)
            } else {
                currentElapsedTime = elapsedTime.timeInterval
            }
            elapsedTimeInterval = currentElapsedTime
        } else if let statisticsArray = try NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: HKStatistics.self, from: data) {
            for statistics in statisticsArray {
                updateForStatistics(statistics)
            }
        }
    }
}

// MARK: - Fetching workouts and workout quantity collections.
//
extension WorkoutManager {
    func fetchTodaysWorkouts(workoutType: HKWorkoutActivityType) async -> [HKWorkout] {
        let samples = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: .now)
            
            guard let startDate = calendar.date(from: components),
                  let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else {
                Logger.shared.log("Failed to create dates from: \(components)")
                continuation.resume(returning: [])
                return
            }
            
            let todayPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])
            let cyclingPredicate = HKQuery.predicateForWorkouts(with: .cycling)
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [todayPredicate, cyclingPredicate])
            
            let sortByStartDate = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            
            let query = HKSampleQuery(sampleType: .workoutType(),
                                      predicate: compoundPredicate,
                                      limit: HKObjectQueryNoLimit,
                                      sortDescriptors: [sortByStartDate]) { (query, samples, error) in
                if let error {
                    Logger.shared.log("Failed to run a sample query: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: samples!)
            }
            healthStore.execute(query)
        }
        let workouts = samples as? [HKWorkout]
        return workouts == nil ? [] : workouts!
    }
    
    func fetchQuantityCollection(for workout: HKWorkout,
                                 quantityTypeIdentifier: HKQuantityTypeIdentifier,
                                 statisticsOptions: HKStatisticsOptions) async -> [HKStatistics] {
        let results = try? await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKStatistics], Error>) in
            let calendar = Calendar.current
            let interval = DateComponents(minute: 1)
            let components = DateComponents(calendar: calendar, timeZone: calendar.timeZone, second: 59)
            
            guard let anchorDate = calendar.nextDate(after: Date(),
                                                     matching: components,
                                                     matchingPolicy: .nextTime,
                                                     repeatedTimePolicy: .first,
                                                     direction: .backward) else {
                Logger.shared.log("Failed to calculate the anchor date.")
                continuation.resume(returning: [])
                return
            }
            
            let predicateForWorkout = HKQuery.predicateForObjects(from: workout)
            let quantityType = HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!
            let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                    quantitySamplePredicate: predicateForWorkout,
                                                    options: statisticsOptions,
                                                    anchorDate: anchorDate,
                                                    intervalComponents: interval)
            
            query.initialResultsHandler = { (query, results, error) in
                if let error = error {
                    Logger.shared.log("Failed to run a statistics collection query: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                var collection = [HKStatistics]()
                results?.enumerateStatistics(from: workout.startDate, to: workout.endDate) { (statistics, stop) in
                    collection.append(statistics)
                }
                continuation.resume(returning: collection)
            }
            healthStore.execute(query)
        }
        return results ?? []
    }
}
