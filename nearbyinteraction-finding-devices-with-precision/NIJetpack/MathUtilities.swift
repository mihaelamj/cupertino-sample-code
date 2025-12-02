/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A math utility method to scale to a range based on a domain.
*/

extension Float {
    func scale(minRange: Float, maxRange: Float, minDomain: Float, maxDomain: Float) -> Float {
        return minDomain + (maxDomain - minDomain) * (max(minRange, min(self, maxRange)) - minRange) / (maxRange - minRange)
    }
}
