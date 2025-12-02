/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The component holding colors for the materials to change over the course of the day.
*/

import RealityKit
// Ensure you register this component in your app’s delegate using:
// TimeOfDayMaterialComponent.registerComponent()
public struct TimeOfDayMaterialComponent: Component, Codable {
    public var timeOfDay: Float = 0.0
    public var fogColorUpperParameterName: String = "FogColorUpper"
    public var fogColorLowerParameterName: String = "FogColorLower"
    public var fogColorSideParameterName: String = "SideFogColor"
    public var fogOpacitySideParameterName: String = "SideFogOpacity"
    public var cloudColorParameterName: String = "CloudColor"
    public var overheadCloudBaseColorParameterName: String = "CloudBaseColor"
    public var overheadCloudEmissiveColorParameterName: String = "CloudEmissiveColor"

    var numberOfColorsInUse: Int = 8

    public var time0: Float = 0.0
    public var fogColorUpper0: SIMD3<Float> = [0, 0, 0]
    public var fogColorLower0: SIMD3<Float> = [0, 0, 0]
    public var fogColorSide0: SIMD3<Float> = [0, 0, 0]
    public var fogOpacitySide0: Float = 1.0
    public var cloudColor0: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudBaseColor0: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudEmissiveColor0: SIMD3<Float> = [0, 0, 0]

    public var time1: Float = 0.14
    public var fogColorUpper1: SIMD3<Float> = [0, 0, 0]
    public var fogColorLower1: SIMD3<Float> = [0, 0, 0]
    public var fogColorSide1: SIMD3<Float> = [0, 0, 0]
    public var fogOpacitySide1: Float = 1.0
    public var cloudColor1: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudBaseColor1: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudEmissiveColor1: SIMD3<Float> = [0, 0, 0]

    public var time2: Float = 0.28
    public var fogColorUpper2: SIMD3<Float> = [0, 0, 0]
    public var fogColorLower2: SIMD3<Float> = [0, 0, 0]
    public var fogColorSide2: SIMD3<Float> = [0, 0, 0]
    public var fogOpacitySide2: Float = 1.0
    public var cloudColor2: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudBaseColor2: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudEmissiveColor2: SIMD3<Float> = [0, 0, 0]

    public var time3: Float = 0.42
    public var fogColorUpper3: SIMD3<Float> = [0, 0, 0]
    public var fogColorLower3: SIMD3<Float> = [0, 0, 0]
    public var fogColorSide3: SIMD3<Float> = [0, 0, 0]
    public var fogOpacitySide3: Float = 1.0
    public var cloudColor3: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudBaseColor3: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudEmissiveColor3: SIMD3<Float> = [0, 0, 0]

    public var time4: Float = 0.57
    public var fogColorUpper4: SIMD3<Float> = [0, 0, 0]
    public var fogColorLower4: SIMD3<Float> = [0, 0, 0]
    public var fogColorSide4: SIMD3<Float> = [0, 0, 0]
    public var fogOpacitySide4: Float = 1.0
    public var cloudColor4: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudBaseColor4: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudEmissiveColor4: SIMD3<Float> = [0, 0, 0]
    
    public var time5: Float = 0.71
    public var fogColorUpper5: SIMD3<Float> = [0, 0, 0]
    public var fogColorLower5: SIMD3<Float> = [0, 0, 0]
    public var fogColorSide5: SIMD3<Float> = [0, 0, 0]
    public var fogOpacitySide5: Float = 1.0
    public var cloudColor5: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudBaseColor5: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudEmissiveColor5: SIMD3<Float> = [0, 0, 0]
    
    public var time6: Float = 0.85
    public var fogColorUpper6: SIMD3<Float> = [0, 0, 0]
    public var fogColorLower6: SIMD3<Float> = [0, 0, 0]
    public var fogColorSide6: SIMD3<Float> = [0, 0, 0]
    public var fogOpacitySide6: Float = 1.0
    public var cloudColor6: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudBaseColor6: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudEmissiveColor6: SIMD3<Float> = [0, 0, 0]

    public var time7: Float = 1.0
    public var fogColorUpper7: SIMD3<Float> = [0, 0, 0]
    public var fogColorLower7: SIMD3<Float> = [0, 0, 0]
    public var fogColorSide7: SIMD3<Float> = [0, 0, 0]
    public var fogOpacitySide7: Float = 1.0
    public var cloudColor7: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudBaseColor7: SIMD3<Float> = [0, 0, 0]
    public var overheadCloudEmissiveColor7: SIMD3<Float> = [0, 0, 0]

    public func interpolateFogColorUpper(timeOfDay: Float) -> SIMD3<Float> {
        let times = [time0, time1, time2, time3, time4, time5, time6, time7]
        let colors = [fogColorUpper0, fogColorUpper1, fogColorUpper2, fogColorUpper3, fogColorUpper4, fogColorUpper5, fogColorUpper6, fogColorUpper7]
        let gradient = ValueGradient(values: colors, times: times, count: numberOfColorsInUse)
        guard let result = gradient.value(at: timeOfDay) else {
            return fogColorUpper0
        }
        return result
    }

    public func interpolateFogColorLower(timeOfDay: Float) -> SIMD3<Float> {
        let times = [time0, time1, time2, time3, time4, time5, time6, time7]
        let colors = [fogColorLower0, fogColorLower1, fogColorLower2, fogColorLower3, fogColorLower4, fogColorLower5, fogColorLower6, fogColorLower7]
        let gradient = ValueGradient(values: colors, times: times, count: numberOfColorsInUse)
        guard let result = gradient.value(at: timeOfDay) else {
            return fogColorLower0
        }
        return result
    }

    public func interpolateFogColorSide(timeOfDay: Float) -> SIMD3<Float> {
        let times = [time0, time1, time2, time3, time4, time5, time6, time7]
        let colors = [fogColorSide0, fogColorSide1, fogColorSide2, fogColorSide3, fogColorSide4, fogColorSide5, fogColorSide6, fogColorSide7]
        let gradient = ValueGradient(values: colors, times: times, count: numberOfColorsInUse)
        guard let result = gradient.value(at: timeOfDay) else {
            return fogColorSide0
        }
        return result
    }

    public func interpolateFogOpacitySide(timeOfDay: Float) -> Float {
        let times = [time0, time1, time2, time3, time4, time5, time6, time7]
        let opacities = [fogOpacitySide0, fogOpacitySide1, fogOpacitySide2, fogOpacitySide3, fogOpacitySide4, fogOpacitySide5, fogOpacitySide6, fogOpacitySide7]
        let gradient = ValueGradient(values: opacities, times: times, count: numberOfColorsInUse)
        guard let result = gradient.value(at: timeOfDay) else {
            return fogOpacitySide0
        }
        return result
    }

    public func interpolateCloudColor(timeOfDay: Float) -> SIMD3<Float> {
        let times = [time0, time1, time2, time3, time4, time5, time6, time7]
        let colors = [cloudColor0, cloudColor1, cloudColor2, cloudColor3, cloudColor4, cloudColor5, cloudColor6, cloudColor7]
        let gradient = ValueGradient(values: colors, times: times, count: numberOfColorsInUse)
        guard let result = gradient.value(at: timeOfDay) else {
            return cloudColor0
        }
        return result
    }
    
    public func interpolateOverheadCloudBaseColor(timeOfDay: Float) -> SIMD3<Float> {
        let times = [time0, time1, time2, time3, time4, time5, time6, time7]
        let colors = [overheadCloudBaseColor0, overheadCloudBaseColor1, overheadCloudBaseColor2, overheadCloudBaseColor3, overheadCloudBaseColor4, overheadCloudBaseColor5, overheadCloudBaseColor6, overheadCloudBaseColor7]
        let gradient = ValueGradient(values: colors, times: times, count: numberOfColorsInUse)
        guard let result = gradient.value(at: timeOfDay) else {
            return overheadCloudBaseColor0
        }
        return result
    }
    
    public func interpolateOverheadCloudEmissiveColor(timeOfDay: Float) -> SIMD3<Float> {
        let times = [time0, time1, time2, time3, time4, time5, time6, time7 ]
        let colors = [overheadCloudEmissiveColor0, overheadCloudEmissiveColor1, overheadCloudEmissiveColor2, overheadCloudEmissiveColor3, overheadCloudEmissiveColor4, overheadCloudEmissiveColor5, overheadCloudEmissiveColor6, overheadCloudEmissiveColor7]
        let gradient = ValueGradient(values: colors, times: times, count: numberOfColorsInUse)
        guard let result = gradient.value(at: timeOfDay) else {
                return overheadCloudEmissiveColor0
        }
        return result
    }
}
