/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The card layout of the main display board.
*/

import SwiftUI
import GameplayKit

struct DisplayBoardCardLayout<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        PoissonDiskLayout(
            sampleAnchor: UnitPoint(x: 0.4, y: 0.3),
            sampleRadius: 150
        ) {
            content
        }
        .padding(EdgeInsets(top: 88, leading: 66, bottom: 22, trailing: 66))
    }
}

struct DisplayBoardSectionCardLayout<Content: View>: View {
    @ViewBuilder var content: Content
    
    @State private var sectionSeed: UInt64 = 0
    
    var body: some View {
        PoissonDiskLayout(
            sampleAnchor: UnitPoint(x: 0.2, y: 0.1),
            sampleRadius: 88,
            randomSeed: sectionSeed
        ) {
            content
        }
        .padding(EdgeInsets(top: 66, leading: 66, bottom: 22, trailing: 66))
        .task {
            let offset = sectionRandomSeedOffset
            sectionRandomSeedOffset += 1
            sectionSeed = DisplayBoardRandomGenerator.defaultSeed(offsetBy: offset)
        }
    }
}

@MainActor
private var sectionRandomSeedOffset: UInt64 = 0

// MARK: - Poisson Disk Layout

/// A layout that positions its contents randomly, maintaining a minimum
/// distance between any two positions.
///
/// If there is no more space to fit new subviews and still maintain the minimum
/// distance, then the minimum distance gradually shrinks until new positions
/// become available, filling in the gaps between existing positions.
private struct PoissonDiskLayout: Layout {
    struct Cache {
        var sampler: PoissonDiskSampler
        var randomNumberGenerator: DisplayBoardRandomGenerator
    }
    
    var sampleAnchor: UnitPoint = .center
    var sampleRadius: CGFloat
    var sampleSpacing: ClosedRange<CGFloat> = 0...20
    var randomSeed: UInt64 = 0

    func makeCache(samplerSize: CGSize) -> Cache {
        let sampler = PoissonDiskSampler(
            bounds: CGRect(
                origin: CGPoint(
                    x: -0.5 * samplerSize.width,
                    y: -0.5 * samplerSize.height),
                size: samplerSize),
            minDistance: 2 * sampleRadius)
        
        let randomNumberGenerator = DisplayBoardRandomGenerator(seed: randomSeed)
        return Cache(sampler: sampler, randomNumberGenerator: randomNumberGenerator)
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        makeCache(samplerSize: .zero)
    }
    
    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        // Pick a starting location.
        if cache.sampler.samples.isEmpty {
            cache.sampler.sample(at: CGPoint(
                x: sampleAnchor.x * cache.sampler.bounds.width,
                y: sampleAnchor.y * cache.sampler.bounds.height))
        }
        
        // Try to find enough positions for all subviews.
        cache.sampler.fill(
            upToCount: subviews.count,
            spacing: sampleSpacing,
            using: &cache.randomNumberGenerator)
    }
    
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }
    
    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        if cache.sampler.bounds.size != bounds.size {
            cache = makeCache(samplerSize: bounds.size)
            updateCache(&cache, subviews: subviews)
        }
        
        for (index, subview) in subviews.enumerated() {
            var position: CGPoint = .zero
            
            // Prefer the position configured via container values, if it
            // exists. Otherwise, use the default calculated position.
            if let currentPosition = subview.containerValues.displayBoardCardPosition {
                position = CGPoint(
                    x: currentPosition.x * bounds.width,
                    y: currentPosition.y * bounds.height)
            } else if !cache.sampler.samples.isEmpty {
                position = cache.sampler.samples[index % cache.sampler.samples.count]
            }
            
            position.x += bounds.midX
            position.y += bounds.midY
            
            // Propose a default card size that would avoid collisions with
            // other cards at the same default size. Note that this is just a
            // default proposal: cards may size themselves differently based on
            // their content, and so collisions are always possible, but that's
            // acceptable for intended aesthetic of the display board.
            let proposedCardSize = ProposedViewSize(
                width: cache.sampler.minDistance,
                height: cache.sampler.minDistance)
            
            subview.place(at: position, anchor: .center, proposal: proposedCardSize)
        }
    }
}

// MARK: - Poisson Disk Sampling

private struct PoissonDiskSampler {
    let bounds: CGRect
    private(set) var minDistance: CGFloat
    private(set) var samples: [CGPoint] = []
    
    /// Indices for elements in `samples` that are assumed to no longer have any
    /// valid candidate positions in range, based on previous searches.
    private var inactiveIndices = RangeSet<Int>()
    
    init(bounds: CGRect, minDistance: CGFloat) {
        self.bounds = bounds
        self.minDistance = minDistance
    }
    
    /// Returns whether the given point is within `bounds` and not too close to
    /// any existing sample.
    func isValidPoint(_ point: CGPoint) -> Bool {
        guard bounds.contains(point) else { return false }
        guard !samples.isEmpty else { return true }
        
        let minDistanceSquared = (minDistance * minDistance)
        
        return samples.allSatisfy { sample in
            let deltaX = sample.x - point.x
            let deltaY = sample.y - point.y
            return (deltaX * deltaX) + (deltaY * deltaY) >= minDistanceSquared
        }
    }
    
    mutating func fill(
        upToCount count: Int,
        spacing: ClosedRange<CGFloat> = 0...0,
        using rng: inout some RandomNumberGenerator
    ) {
        var delta = count - samples.count
        while delta > 0 {
            if sample(spacing: spacing, using: &rng) != nil {
                delta -= 1
            } else {
                let distance = 0.9 * minDistance
                guard distance >= 10 else { break }
                minDistance = distance
                inactiveIndices = .init()
            }
        }
    }
    
    @discardableResult
    mutating func sample(at point: CGPoint) -> CGPoint? {
        guard isValidPoint(point) else { return nil }
        samples.append(point)
        return point
    }
    
    @discardableResult
    mutating func sample(
        spacing: ClosedRange<CGFloat> = 0...0,
        using rng: inout some RandomNumberGenerator
    ) -> CGPoint? {
        guard !samples.isEmpty else { return sample(at: .zero) }
        
        let lowerBound = minDistance + spacing.lowerBound
        let upperBound = minDistance + spacing.upperBound
        let distanceBounds = lowerBound...upperBound
        
        // Choose an active sample.
        while let index = samples.indices.removingSubranges(inactiveIndices).first {
            let sample = samples[index]
            
            // Test random candidates within the search radius range.
            for _ in 0 ..< 20 {
                let direction: Angle = .degrees(.random(in: 0..<360, using: &rng))
                let distance: CGFloat = .random(in: distanceBounds, using: &rng)
                let candidate = CGPoint(
                    x: sample.x + distance * cos(direction.radians),
                    y: sample.y + distance * sin(direction.radians))
                
                if let point = self.sample(at: candidate) {
                    return point
                }
            }
            
            // No valid candidates found, deactivate sample.
            inactiveIndices.insert(index, within: samples)
        }
        
        return nil
    }
}

// MARK: - Previews

#Preview("Circles", traits: .landscapeLeft) {
    PoissonDiskLayout(sampleAnchor: .center, sampleRadius: 44) {
        ForEach(0 ..< 30) { _ in
            CircleAreaView()
        }
    }
    .border(.red)
    .padding(100)
    .ignoresSafeArea()
}

#Preview("Cards", traits: .landscapeLeft) {
    DisplayBoardCardLayout {
        ForEach(0 ..< 30) { _ in
            CardView {
                Text("Hello")
            }
        }
    }
    .border(.red)
    .padding(100)
    .ignoresSafeArea()
}

private struct CircleAreaView: View {
    var body: some View {
        ZStack {
            ZStack {
                Circle()
                    .fill(.quaternary.opacity(0.5))
                Circle()
                    .stroke(.secondary)
            }
            Circle()
                .fill(.primary)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(.blue)
    }
}
