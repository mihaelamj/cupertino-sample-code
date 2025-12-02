/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Math extensions.
*/

protocol Interpolatable<Interpolator> {
    associatedtype Interpolator: BinaryFloatingPoint
    static func *(lhs: Self, rhs: Interpolator) -> Self
    static func *(lhs: Interpolator, rhs: Self) -> Self
    static func +(lhs: Self, rhs: Self) -> Self
}

extension Double: Interpolatable {
    typealias Interpolator = Float
    
    static func *(lhs: Double, rhs: Float) -> Double {
        return Double(rhs) * lhs
    }

    static func *(lhs: Float, rhs: Double) -> Double {
        return Double(lhs) * rhs
    }
}

extension Float: Interpolatable {
    typealias Interpolator = Float
}

extension SIMD3<Float>: Interpolatable {
    typealias Interpolator = Float
}

extension SIMD4<Float>: Interpolatable {
    typealias Interpolator = Float
}

struct ValueGradient<Element> where Element: Interpolatable {
    let values: [Element]
    let count: Int
    var times: [Element.Interpolator]
    
    init(values: [Element], times: [Element.Interpolator], count: Int) {
        self.values = values
        self.times = times
        self.count = min(min(count, values.count), times.count)
    }
    
    init(values: [Element], count: Int) {
        self.values = values
        self.count = min(count, values.count)
        
        // if no custom `times` list is supplied, assume equal linear interpolation between all values
        self.times = .init(repeating: 0, count: self.count)
        for value in 0..<self.count {
            self.times[value] = Element.Interpolator(value) / Element.Interpolator(self.count - 1)
        }
    }

    init(values: [Element]) {
        self.values = values
        
        // if no count provided, assume values.count
        self.count = values.count
        
        // if no custom `times` list is supplied, assume equal linear interpolation between all values
        self.times = .init(repeating: 0, count: self.count)
        for value in 0..<self.count {
            self.times[value] = Element.Interpolator(value) / Element.Interpolator(self.count)
        }
    }

    /// Returns the interpolated value based on `t` the list of `values`
    /// This is modeled after Gradient, each element in the `values` is a stop
    /// `t` is from 0.0 to 1.0, 0.0 is elments[0], 1.0 is values.last
    func value(at t: Element.Interpolator) -> Element? {
        if count == 0 {
            return nil
        }

        // if t < 0, just return the 1st value
        if count == 1 || t <= 0.0 {
            return values[0]
        }
        
        // otherwise, step through the `times` list until we find out which two times this `t` is between.
        // NOTE: this assumes that `times` is sorted in increasing order (a safe assumption for our use case).
        for time in 0..<(count - 1) {
            if times[time] <= t && t < times[time + 1] {
                let newT: Element.Interpolator = (t - times[time]) / (times[time + 1] - times[time])
                return (1.0 - newT) * values[time] + newT * values[time + 1]
            }
        }
        
        // If `t` wasn't between any two times, just return the last value.
        return values[count - 1]
    }
}
