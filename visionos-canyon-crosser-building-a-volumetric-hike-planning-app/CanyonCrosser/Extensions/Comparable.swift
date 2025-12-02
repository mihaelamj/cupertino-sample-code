/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions on `Comparable`.
*/
extension Comparable {
    /// Returns the value limited to the specified range.
    /// - Parameter limits: The range of values to return.
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}
