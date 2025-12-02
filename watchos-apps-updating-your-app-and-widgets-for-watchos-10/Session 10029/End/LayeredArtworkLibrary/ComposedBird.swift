/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The composed bird.
*/

import BackyardBirdsData
import SwiftUI

public struct ComposedBird: View {
    var bird: Bird
    var direction: HorizontalEdge
    
    public init(bird: Bird, direction: HorizontalEdge = .leading) {
        self.bird = bird
        self.direction = direction
    }
    
    public var body: some View {
//        TimelineView(.animation) { context in
            ZStack {
                ForEach(bird.species.parts) { part in
//                    if let frameCount = part.flipbookFrameCount {
                    if part.flipbookFrameCount != nil {
//                        let frameIndex = frameIndex(date: context.date, frameCount: frameCount)
//                        ForEach(0..<frameCount, id: \.self) { i in
                        let i = 0
                            Image("\(bird.species.id)/\(part.name)\(i + 1)", bundle: .module)
                                .resizable()
                                .scaledToFit()
                                .colorMultiply(bird.colors.colorData(for: part.colorStyle).color)
//                                .opacity(frameIndex == i ? 1 : 0)
//                        }
                    } else {
                        Image("\(bird.species.id)/\(part.name)", bundle: .module)
                            .resizable()
                            .scaledToFit()
                            .colorMultiply(bird.colors.colorData(for: part.colorStyle).color)
                    }
                }
            }
//        }
          .scaleEffect(x: direction == .trailing ? 1 : -1)
          .flipsForRightToLeftLayoutDirection(true)
          .id(bird.id)
    }
    
    func frameIndex(date: Date, frameCount: Int) -> Int {
        let totalSeconds = date.timeIntervalSince1970
        let duration = TimeInterval(frameCount) * 0.1
        let seconds = totalSeconds.truncatingRemainder(dividingBy: duration)
        let progress = seconds / duration
        let frame = Int(floor(progress * Double(frameCount)))
        return frame
    }
}

#Preview {
    ModelPreview { bird in
        ComposedBird(bird: bird)
    }
}
