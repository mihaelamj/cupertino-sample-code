/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility functions for calculating projectile motion.
*/

import Foundation

public struct ProjectileMotionUtilities {
    private init() {}
    
    // Calculates the initial vertical velocity a projectile needs to reach a given vertical height.
    public static func calculateVelocityNeededToReachHeight(height: Float, gravity: Float) -> Float {
        sqrt(2 * abs(gravity) * height)
    }
    
    // Calculates the amount of time it takes a projectile to reach its maximum height given its vertical velocity.
    public static func calculateTimeToReachMaxHeight(velocity: Float, gravity: Float) -> Float {
        velocity / abs(gravity)
    }
    
    // Calculates the velocity a projectile needs to travel a given distance before returning to a given target velocity,
    // assuming a constant slowing acceleration force in the opposite direction of the projectile's velocity.
    public static func calculateVelocityNeededToTravelDistanceBeforeReachingTargetVelocity(distance: Float,
                                                                                           targetVelocity: Float,
                                                                                           slowingAcceleration: Float) -> Float {
        sqrt(2 * slowingAcceleration * distance + targetVelocity * targetVelocity)
    }
    
    public static func calculateBrakingDistance(velocity: Float, acceleration: Float) -> Float {
        velocity * velocity / (2 * acceleration)
    }
}
