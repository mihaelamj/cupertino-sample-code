/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension on `GrandCanyonView` to animate and update the trail and hiker.
*/

import SwiftUI
import RealityKit
import RealityKitContent

extension GrandCanyonView {

    /// Performs the necessary updates to the hiker animation based on the current progress of the hike.
    /// - Parameter trailAnimationProgress: The current progress of the hike, as a value between 0 and 1.
    private func updateAnimationForProgress(trailAnimationProgress: TrailAnimationProgress) {
        guard let animationPlaybackController = appModel.getHikerAnimationPlaybackController() else {
            return
        }

        animationPlaybackController.time = Double(trailAnimationProgress.progress) * animationPlaybackController.duration

        appModel.hikerEntity.children.forEach {
            $0.transform.rotation = simd_quatf(angle: trailAnimationProgress.returningBack ? .pi : 0.0, axis: [0, 1, 0])
        }
    }

    /// Performs the necessary updates to the trail line progress based on the current progress of the hike.
    /// - Parameters:
    ///   - trailPercentage: The current progress of the hike, as a value between `0` and `1`.
    ///   - goingBackUp: If the hiker is returning up the trail.
    ///   - path: The path to the entity whose material should be updated.
    private func updateTrailLineProgress(trailPercentage: Percentage, goingBackUp: Bool, path: String) {
        guard
            let entity = appModel.grandCanyonEntity.childAt(path: path),
            var modelComponent = entity.components[ModelComponent.self],
            var material = modelComponent.materials.first as? ShaderGraphMaterial
        else {
            print("""
                Unable to get the Shader Graph material.
                entity = \(String(describing: appModel.grandCanyonEntity.childAt(path: path)))
                modelComponent = \(String(describing: appModel.grandCanyonEntity.childAt(path: path)?.components[ModelComponent.self]))
                material = \(String(describing: appModel.grandCanyonEntity.childAt(path: path)?.components[ModelComponent.self]?.materials.first))
                """)
            return
        }

        do {
            try material.setParameter(name: "PercentCompleted", value: .float(trailPercentage))

            let transitionPercentage: Float = 2
            let trailPercentageToStartTransition = 1.0 - (transitionPercentage / 100)
            let goingBackUpValue: Float = {
                guard goingBackUp, trailPercentage > trailPercentageToStartTransition else {
                    return goingBackUp ? 1.0 : 0.0
                }

                return (1.0 - trailPercentage) * 100 / transitionPercentage
            }()
            try material.setParameter(name: "GoingBackUp", value: .float(goingBackUpValue))

            modelComponent.materials = [material]
            entity.components[ModelComponent.self] = modelComponent
        } catch {
            print("Failed to set PercentCompleted on shader graph material: \(error)")
        }
    }

    /// Performs animations for the trail and hiker based on the current progress.
    /// - Parameter selectedHike: The hike to use for the animation.
    func updateTrailAndHiker(selectedHike: Hike) {
        // Animate the trail and hiker as progress changes.
        let trailAnimationProgress = calculateTrailProgressFrom(
            hikeProgress: appModel.hikerProgressComponent.hikeProgress,
            hikingDuration: Float(selectedHike.length) * 60, // Given a 1 mph hiking speed multiply by 60 to get duration in minutes.
            restStopLocations: appModel.hikeTimingComponent.restStopRestDurations
        )
        updateAnimationForProgress(trailAnimationProgress: trailAnimationProgress)
        updateTrailLineProgress(
            trailPercentage: trailAnimationProgress.progress,
            goingBackUp: trailAnimationProgress.returningBack,
            path: selectedHike.trailEntityPath
        )

        // Set the hiker state depending on progress change.
        if trailAnimationProgress.location != nil {
            appModel.setHikerVisibility(state: .sitting)
        } else if [0.0, 1.0].contains(trailAnimationProgress.progress) {
            appModel.setHikerVisibility(state: .standing)
        } else {
            appModel.setHikerVisibility(state: .walking)
        }
    }

    /// Calculates the progress for an out-and-back hike, accounting for rest stops.
    /// This functions maps a `hikeProgress` of 0.0 to 1.0 to a`TrailAnimationProgress.progress` of `0.0` to `1.0` to `0.0`.
    /// Rest stop locations are based on their start time as a fraction of this total round trip hiking time.
    ///
    /// - Parameters:
    ///   - hikeProgress: The fraction of the hike duration (hiking time including rest stops) that has passed (`0.0` to `1.0`).
    ///   - hikingDuration: The total time in minutes spent actually hiking the entire round trip (excluding rest stops).
    ///   - restStops: An array of `RestStop` structures that define the rest stops relative to the total hiking time.
    /// - Returns: A `TrailAnimationProgress` that contains the information for the current progress on the trail.
    private func calculateTrailProgressFrom(
        hikeProgress currentHikeProgress: Float,
        hikingDuration hikingDurationWithoutRestStops: Float,
        restStopLocations: [RestStopLocation: Int]
    ) -> TrailAnimationProgress {
        // Return zero when the total hiking time hasn't been established.
        guard hikingDurationWithoutRestStops > 0 else {
            return .zero
        }

        /// The total amount of time that the hike takes, inclusive of rest durations.
        let hikingDurationWithRestStops = hikingDurationWithoutRestStops + restStopLocations.values.reduce(0) { $0 + Float($1) }

        /// The duration of the hike.
        let currentHikeDuration = currentHikeProgress * hikingDurationWithRestStops

        /// Hiking time completed before the start of the current segment.
        var accumulatedHikingTime: Float = 0.0

        /// Total time elapsed at the end of the previous rest stop.
        var accumulatedTotalTime: Float = 0.0

        for restStopLocation in restStopLocations.sorted(by: { $0.key.trailPercentage < $1.key.trailPercentage }) {
            /// The amount of time spent hiking excluding rest stops.
            let hikingTimeAtStartOfRestStop = restStopLocation.key.trailPercentage * Float(hikingDurationWithoutRestStops)

            /// The absolute time when this rest stop starts.
            let totalTimeAtStartOfRestStop = accumulatedTotalTime - accumulatedHikingTime + hikingTimeAtStartOfRestStop

            if currentHikeDuration <= totalTimeAtStartOfRestStop {
                let hikingTimeInThisSegment = currentHikeDuration - accumulatedTotalTime

                return trailAnimationProgress(
                    from: (accumulatedHikingTime + hikingTimeInThisSegment) / hikingDurationWithoutRestStops,
                    at: nil
                )
            }

            /// The total hike time when the time at the rest stop ends.
            let totalTimeAtRestStopEnd = totalTimeAtStartOfRestStop + Float(restStopLocation.value)

            if currentHikeDuration <= totalTimeAtRestStopEnd {
                return trailAnimationProgress(
                    from: hikingTimeAtStartOfRestStop / hikingDurationWithoutRestStops,
                    at: restStopLocation.key
                )
            }

            accumulatedHikingTime = hikingTimeAtStartOfRestStop
            accumulatedTotalTime = totalTimeAtRestStopEnd
        }

        let hikingTimeAfterLastRestStop = currentHikeDuration - accumulatedTotalTime
        let finalActualHikingTime = accumulatedHikingTime + hikingTimeAfterLastRestStop

        return trailAnimationProgress(
            from: finalActualHikingTime / hikingDurationWithoutRestStops,
            at: nil
        )
    }

    /// Converts the round trip progress into a hike in or hike out progress.
    ///
    /// - Parameters:
    ///   - roundTripProgress: The progress for the entire round trip (`0.0` to `1.0`).
    ///   - location: The location that the user is currently resting at.
    /// - Returns: The progress along the hiking trail, rest stop, and a Boolean that determines whether the hike inbound or outbound.
    private func trailAnimationProgress(from roundTripProgress: Float, at location: RestStopLocation?) -> TrailAnimationProgress {
        if roundTripProgress <= 0.5 {
            // Map `[0.0, 0.5]` to `[0.0, 1.0]` for the inbound hike.
            return .init(
                progress: roundTripProgress * 2.0,
                location: location,
                returningBack: false
            )
        } else {
            // Map `[0.5, 1.0]` to `[1.0, 0.0]` for the return journey.
            return .init(
                progress: (1.0 - roundTripProgress) * 2.0,
                location: location,
                returningBack: true
            )
        }
    }
}

