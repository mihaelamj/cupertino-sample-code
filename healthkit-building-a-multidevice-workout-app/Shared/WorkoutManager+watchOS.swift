/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions that wrap workout operations specific to watchOS.
*/

import Foundation
import os
import HealthKit

// MARK: - Workout session management
//
extension WorkoutManager {
    /**
     Use healthStore.requestAuthorization to request authorization in watchOS when
     healthDataAccessRequest isn't available yet.
     */
    func requestAuthorization() {
        Task {
            do {
                try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            } catch {
                Logger.shared.log("Failed to request authorization: \(error)")
            }
        }
    }
    
    func startWorkout(workoutConfiguration: HKWorkoutConfiguration) async throws {
        session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration)
        builder = session?.associatedWorkoutBuilder()
        session?.delegate = self
        builder?.delegate = self
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: workoutConfiguration)
        /**
          Start mirroring the session to the companion device.
         */
        try await session?.startMirroringToCompanionDevice()
        /**
          Start the workout session activity.
         */
        let startDate = Date()
        session?.startActivity(with: startDate)
        try await builder?.beginCollection(at: startDate)
    }
    
    func handleReceivedData(_ data: Data) throws {
        guard let decodedQuantity = try NSKeyedUnarchiver.unarchivedObject(ofClass: HKQuantity.self, from: data) else {
            return
        }
        water += decodedQuantity.doubleValue(for: HKUnit.fluidOunceUS())

        let sampleDate = Date()
        Task {
            let waterSample = [HKQuantitySample(type: HKQuantityType(.dietaryWater), quantity: decodedQuantity, start: sampleDate, end: sampleDate)]
            try await builder?.addSamples(waterSample)
        }
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
// HealthKit calls the delegate methods on an anonymous serial background queue,
// so the methods need to be nonisolated explicitly.
//
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        /**
          HealthKit calls this method on an anonymous serial background queue.
          Use Task to provide an asynchronous context so MainActor can come to play.
         */
        Task { @MainActor in
            var allStatistics: [HKStatistics] = []
            
            for type in collectedTypes {
                if let quantityType = type as? HKQuantityType, let statistics = workoutBuilder.statistics(for: quantityType) {
                    updateForStatistics(statistics)
                    allStatistics.append(statistics)
                }
            }
            
            let archivedData = try? NSKeyedArchiver.archivedData(withRootObject: allStatistics, requiringSecureCoding: true)
            guard let archivedData = archivedData, !archivedData.isEmpty else {
                Logger.shared.log("Encoded cycling data is empty")
                return
            }
            /**
              Send a Data object to the connected remote workout session.
             */
            await sendData(archivedData)
        }
    }
    
    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
}
