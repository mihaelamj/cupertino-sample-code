/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A random number generator this app uses throughout.
*/

import SwiftUI
import GameplayKit

final class DisplayBoardRandomGenerator: RandomNumberGenerator {
    private var randomSource: any GKRandom
    
    init(seed: UInt64? = defaultSeed) {
        randomSource = seed.map {
            GKMersenneTwisterRandomSource(seed: $0)
        } ?? GKMersenneTwisterRandomSource()
    }
    
    func next() -> UInt64 {
        let high = UInt64(bitPattern: Int64(randomSource.nextInt()))
        let low = UInt64(bitPattern: Int64(randomSource.nextInt()))
        return (high << 32) ^ low
    }
    
    nonisolated static let defaultSeed: UInt64 = 415
    
    nonisolated static func defaultSeed(offsetBy offset: UInt64) -> UInt64 {
        defaultSeed + offset
    }
}

final class CardRandomGenerator {
    @MainActor
    static let main = CardRandomGenerator()
    
    private static let pinColors: [Color] = [
        .blue, .red, .green, .orange, .cyan, .purple, .yellow, .brown
    ]
    
    private var randomSource: any GKRandom
    private var cardRotationDistribution: GKRandomDistribution
    private var cardPinColorDistribution: GKRandomDistribution
    
    init(seed: UInt64? = DisplayBoardRandomGenerator.defaultSeed) {
        randomSource = seed.map { GKMersenneTwisterRandomSource(seed: $0) }
            ?? GKMersenneTwisterRandomSource()
        
        cardRotationDistribution = GKShuffledDistribution(
            randomSource: randomSource,
            lowestValue: 1,
            highestValue: 20)
        
        cardPinColorDistribution = GKShuffledDistribution(
            randomSource: randomSource,
            lowestValue: 0,
            highestValue: Self.pinColors.count - 1)
    }
    
    func nextCardRotation() -> Angle {
        let rotation = Double(cardRotationDistribution.nextUniform())
        return .degrees(rotation * 14.0 - 7.0)
    }
    
    func nextCardPinColor() -> Color {
        Self.pinColors[cardPinColorDistribution.nextInt()]
    }
}
