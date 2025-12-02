/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that stores entities.
*/

import SwiftUI
import Observation
import RealityKit

enum LoadingError: Error {
    case grandCanyon, hiker, birds, clouds, terrain, root, sunlight
}

typealias Hours = Double
typealias Percentage = Float

@MainActor
@Observable
final class AppModel: Sendable {
    var clippingMarginEnvironment = ClippingMarginPercentageComponent.Environment()

    var root: Entity = Entity()
    var hikes: [Hike]

    // Entities for each hike, setup in the loading phase, and turned on and off with `selectedHike`.
    var hikeEntities: [Hike: [Entity]] = [:]

    var selectedHike: Hike? {
        willSet {
            // When going from a hike to no hike.
            if nil == newValue && nil != selectedHike {
                // If the hike was playing, the clouds would be faded out, so fade them in.
                if !hikePlaybackStateComponent.isPaused {
                    fadeInClouds()
                }
            }
        }
        didSet {
            guard oldValue?.name != selectedHike?.name else {
                return
            }

            if let hike = selectedHike {
                configureTimingForHike(hike: hike)
                resetHike()
            }

            // Turn off entities from previously selected hike.
            if
                let oldValue,
                let oldHikeEntities = hikeEntities[oldValue]
            {
                Entity.animateOut(
                    entities: selectedHike == nil ? [hikerEntity] + oldHikeEntities : oldHikeEntities,
                    duration: 0.25
                )
            }

            // Turn on entities on newly-selected hike.
            if
                let hike = selectedHike,
                let newHikeEntities = hikeEntities[hike]
            {
                Entity.animateIn(
                    entities: oldValue == nil ? [hikerEntity] + newHikeEntities : newHikeEntities,
                    duration: 1.0
                )
            }
        }
    }

    var hikerAnimationController: AnimationPlaybackController?
    
    var animationPlaybackControllers: [AnimationPlaybackController] = []
    var debugSettings = DebugSettings()

    var popoverIsPresented: Bool = false

    var grandCanyonEntity = Entity()
    var birdsEntity = Entity()
    var cloudsEntity = Entity()
    var hikerEntity = Entity()
    var birdsAnimation: AnimationResource?
    var birdsAnimationController: AnimationPlaybackController?
    /// The base size of the terrain when the scale is 1.
    var terrainEntityBaseExtents: SIMD3<Float> = .one
    var cloudsAnimation: AnimationResource?
    var cloudsAnimationController: AnimationPlaybackController?

    var sunlight = Entity()

    var extendedBoundsMultiplier: Float = 0.2

    var initialHikeProgressOnDrag: Float = 0

    init() {
        self.hikes = [MockData.brightAngel, MockData.trailOfTime, MockData.matherPoint]
    }

    func fadeInClouds() {
        Entity.animateIn(entities: [cloudsEntity], duration: 3.0)
    }

    func fadeOutClouds() {
        Entity.animateOut(entities: [cloudsEntity], duration: 0.25)
    }

    func getHikerAnimationPlaybackController() -> AnimationPlaybackController? {
        if
            let hikerAnimationController,
            hikerAnimationController.isValid
        {
            // Note: After an animation completes, the playback controller becomes invalid,
            // so the app creates a new controller.
            return hikerAnimationController
        }

        guard let animation = hikerEntity.availableAnimations.first else {
            return nil
        }

        let animationController = hikerEntity.playAnimation(
            animation,
            transitionDuration: 0.0,
            separateAnimatedValue: true,
            startsPaused: true,
        )

        self.hikerAnimationController = animationController

        return animationController
    }

    func setHikerVisibility(state: HikerState) {
        hikerEntity.child(named: .hikerWalking)?.isEnabled = state == .walking
        hikerEntity.child(named: .hikerSitting)?.isEnabled = state == .sitting
        hikerEntity.child(named: .hikerStanding)?.isEnabled = state == .standing
    }
}

