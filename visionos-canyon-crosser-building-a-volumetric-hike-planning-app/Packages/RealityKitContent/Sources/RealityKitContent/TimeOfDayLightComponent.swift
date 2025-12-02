/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The component holding the colors to change light over the course of the day.
*/

import RealityKit

public struct TimeOfDayLightComponent: Component, Codable {
    // the number of colors actually in use. must be <= 8
    var numberOfColorsInUse: Int = 8
    
    // the current time of day
    public var timeOfDay: Float = 0.0
    // the potential light color and intensities in use
    public var time0: Float = 0.0
    public var color0: SIMD3<Float> = [0, 0, 0]
    public var intensity0: Float = 1000.0

    public var time1: Float = 0.14
    public var color1: SIMD3<Float> = [0, 0, 0]
    public var intensity1: Float = 1000.0

    public var time2: Float = 0.28
    public var color2: SIMD3<Float> = [0, 0, 0]
    public var intensity2: Float = 1000.0

    public var time3: Float = 0.42
    public var color3: SIMD3<Float> = [0, 0, 0]
    public var intensity3: Float = 1000.0

    public var time4: Float = 0.57
    public var color4: SIMD3<Float> = [0, 0, 0]
    public var intensity4: Float = 1000.0
    
    public var time5: Float = 0.71
    public var color5: SIMD3<Float> = [0, 0, 0]
    public var intensity5: Float = 1000.0

    public var time6: Float = 0.85
    public var color6: SIMD3<Float> = [0, 0, 0]
    public var intensity6: Float = 1000.0

    public var time7: Float = 1.0
    public var color7: SIMD3<Float> = [0, 0, 0]
    public var intensity7: Float = 1000.0
    
    public init() {
    }
    
    // returns the interpolated light color for the given time of day
    public func interpolateColor(timeOfDay: Float) -> SIMD3<Float> {
        let times: [Float] = [time0, time1, time2, time3, time4, time5, time6, time7]
        let colors: [SIMD3<Float>] = [ color0, color1, color2, color3, color4, color5, color6, color7 ]
        let gradient = ValueGradient(values: colors, times: times, count: numberOfColorsInUse)
        guard let result = gradient.value(at: timeOfDay) else {
            return color0
        }
        return result
    }
    
    // returns the interpolated light intensity for the given time of day
    public func interpolateIntensity(timeOfDay: Float) -> Float {
        let times: [Float] = [time0, time1, time2, time3, time4, time5, time6, time7]
        let intensities: [Float] = [ intensity0, intensity1, intensity2, intensity3, intensity4, intensity5, intensity6, intensity7 ]
        let gradient = ValueGradient(values: intensities, times: times, count: numberOfColorsInUse)
        guard let result = gradient.value(at: timeOfDay) else {
            return intensity0
        }
        return result
    }
}
