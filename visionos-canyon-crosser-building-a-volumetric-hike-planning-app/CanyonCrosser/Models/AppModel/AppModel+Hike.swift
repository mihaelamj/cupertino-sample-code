/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extension on `AppModel` to set hike components.
*/

import Foundation
import RealityKit
import SwiftUI

extension AppModel {
    // MARK: - Hike State observable components

    /// The following computed properties provide access to the components that house the data associated with the hike.
    /// Access the components through the Observable property for use when views need to stay
    /// up to date with any updates.
    ///
    /// To update views only when they require an update, the app uses multiple components to updated the views
    /// at different intervals.
    ///
    /// In `AppModel+Setup.swift`, `hikerEntity` is created with the required components. If the application is refactored such
    /// that this setup process changes or these components are removed these functions will stop the execution of the app.

    var hikeTimingComponent: HikeTimingComponent {
        get {
            guard let component = hikerEntity.observable.components[HikeTimingComponent.self] else { fatalError() }
            return component
        }
        set { hikerEntity.observable.components[HikeTimingComponent.self] = newValue }
    }

    var hikerProgressComponent: HikerProgressComponent {
        get {
            guard let component = hikerEntity.observable.components[HikerProgressComponent.self] else { fatalError() }
            return component
        }
        set { hikerEntity.observable.components[HikerProgressComponent.self] = newValue }
    }

    var hikePlaybackStateComponent: HikePlaybackStateComponent {
        get {
            guard let component = hikerEntity.observable.components[HikePlaybackStateComponent.self] else { fatalError() }
            return component
        }
        set { hikerEntity.observable.components[HikePlaybackStateComponent.self] = newValue }
    }

    var hikerDragStateComponent: HikerDragStateComponent {
        get {
            guard let component = hikerEntity.observable.components[HikerDragStateComponent.self] else { fatalError() }
            return component
        }
        set { hikerEntity.observable.components[HikerDragStateComponent.self] = newValue }
    }

    // MARK: - Computed States

    var shouldAnimateSunlightChange: Bool {
        hikerDragStateComponent.dragState == .none && hikerProgressComponent.animation == nil
    }

    var timelineLabels: [TimelineLabel] {
        guard let hike = selectedHike else { return [] }

        // Get the time distance and round up. Given a 1 mph hiking speed, round the miles up to get the hours.
        var hoursInTimeline = hike.length.rounded(.up)
        // Round down the time of departing to start the timeline before departure.
        let roundedStartTime = hikeTimingComponent.departureDate.roundHourDown()

        // Check if the arrival time is on the hour or 15 minutes past. If greater than 15 minutes past the hour,
        // add an additional hour to the timeline to see the weather for this additional hour.
        // This results in a slider that could show 2 hours of additional time causing the accuracy
        // of the slider time position and hiker percentage to be inaccurate.
        // If a hike ends at 7:20, when the progress is at 100 percent, the slider will be at 8:00.
        if hikeTimingComponent.departureDate.addingTimeInterval(TimeInterval(hoursInTimeline) * .oneHourInSeconds).minutes() > 15 {
            hoursInTimeline += 1
        }

        return (0...Int(hoursInTimeline)).map { hour in
            let labelTime = roundedStartTime.addingTimeInterval(TimeInterval(hour) * .oneHourInSeconds)

            return TimelineLabel(
                time: labelTime,
                weather: MockData.weather[labelTime.hour()]
            )
        }
    }

    // MARK: - Hike Timing Component functions

    func configureTimingForHike(hike: Hike) {
        hikeTimingComponent.hikeLength = hike.length

        // Reset the rest stop durations.
        hikeTimingComponent.restStopRestDurations.removeAll()

        // Reset the departure and arrival times when selecting a new hike.
        hikeTimingComponent.departureDate = MockData.departureTime
    }

    func getRestDuration(for location: RestStopLocation) -> Int {
        hikeTimingComponent.restStopRestDurations[location] ?? 0
    }

    func setRestDuration(_ rest: Int, for location: RestStopLocation) {
        hikeTimingComponent.restStopRestDurations[location] = rest
    }

    // MARK: - Hike Progress Component functions

    func sliderThumbDrag(percentage: Float) {
        // Prevent simultaneous entity and slider dragging.
        guard hikerDragStateComponent.dragState != .entity else {
            return
        }

        // When a drag starts, add the elevation view and fade out the clouds.
        if hikerDragStateComponent.dragState == .none {
            hikerDragStateComponent.dragState = .slider
            fadeOutClouds()
            fadeInHikerElevationView()
        }

        animateProgress(to: percentage)
    }

    func sliderDragCompleted() {
        guard hikerDragStateComponent.dragState == .slider else {
            return
        }

        hikerDragStateComponent.dragState = .none
        fadeInClouds()
        fadeOutHikerElevationView()
    }

    func sliderTapped(percentage: Float) {
        guard hikerDragStateComponent.dragState == .none else { return }

        animateProgress(to: percentage)
    }

    private func animateProgress(to value: Float) {
        hikerProgressComponent.animation = (toValue: value, fromValue: hikerProgressComponent.hikeProgress, elapsedTime: 0)
    }

    // MARK: - Hike Playback State Component functions

    func toggleHikePlaybackState() {
        // When the playback button is tapped with a completed hike, reset the progress to zero.
        if hikerProgressComponent.hikeProgress > 0.999 {
            hikerProgressComponent.hikeProgress = 0.0
        }

        hikePlaybackStateComponent.isPaused.toggle()
    }

    func resetHike() {
        hikePlaybackStateComponent.isPaused = true
        hikerProgressComponent.hikeProgress = 0.0
    }

    // MARK: - Hiker Drag Gesture

    func hikerDragChanged(event: DragGesture.Value) {
        // Prevent simultaneous slider and entity dragging.
        guard hikerDragStateComponent.dragState != .slider else {
            return
        }

        // If the entity wasn't previously dragged, this is the start of a new drag.
        if hikerDragStateComponent.dragState == .none {
            // Store the initial hike progress when the drag began.
            initialHikeProgressOnDrag = hikerProgressComponent.hikeProgress

            fadeOutClouds()
            fadeInHikerElevationView()
        }

        // Store that a drag on the hiker entity is in progress.
        hikerDragStateComponent.dragState = .entity

        // Get the necessary start and end entities for the trail.
        guard let hike = selectedHike else { return }
        guard
            let startEntity = grandCanyonEntity.childAt(path: hike.trailStartEntityName),
            let endEntity = grandCanyonEntity.childAt(path: hike.trailEndEntityName)
        else {
            grandCanyonEntity.printTree()
            assertionFailure("Failed to load '\(hike.trailStartEntityName)' and '\(hike.trailEndEntityName)'")
            return
        }

        hikerProgressComponent.hikeProgress = calculateHikeProgressFromDrag(
            trailVector: endEntity.position(relativeTo: nil) - startEntity.position(relativeTo: nil),
            dragVector: SIMD3<Float>(event.location3D.vector - event.startLocation3D.vector)
        )
    }

    /// Returns the hike progress that results from the given drag vector.
    /// - Parameters:
    ///   - trailVector: The vector from the Grand Canyon to the start of the hike.
    ///   - dragVector: The drag vector from the start of the drag to the current location of the drag.
    ///   - hikerDragMagnitude: How much the drag distance affects the change of the returned value.
    ///
    /// - Returns: The new hike progress value for the drag parameters.
    private func calculateHikeProgressFromDrag(
        trailVector: SIMD3<Float>,
        dragVector: SIMD3<Float>,
        hikerDragMagnitude: Float = 1.00
    ) -> Float {
        // Project the `dragVector` onto the `trailVector`.
        let dragOnTrail = (dot(dragVector, trailVector) / dot(trailVector, trailVector)) * normalize(trailVector)

        /// Length of the drag along the trail, as a percent, to the length of the trail.
        let percentDragOnTrail = length(dragOnTrail) / length(trailVector)

        // Use the reverse trail vector if the hiker is hiking back.
        let currentTrailDirectionVector = initialHikeProgressOnDrag < 0.5 ? trailVector : -trailVector

        // Calculate the change value using the `hikerDragMagnitude` and the direction of the drag vector.
        let changeValueForDrag = Float(
            signOf: dot(dragOnTrail, currentTrailDirectionVector),
            magnitudeOf: percentDragOnTrail * hikerDragMagnitude
        )

        // Return the new progress given the change value and the initial progress at the start of the drag.
        return (changeValueForDrag + initialHikeProgressOnDrag).clamped(to: 0.0...1.0)
    }

    func hikerDragEnded() {
        guard hikerDragStateComponent.dragState == .entity else {
            return
        }

        hikerDragStateComponent.dragState = .none
        fadeInClouds()
        fadeOutHikerElevationView()
    }
}
