/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation for UntilProcessingCompleteFilter that iterates the session outputs.
*/

// An `AsyncSequence` filter to apply to the `PhotogrammetrySession.Outputs` infinite sequence so that it passes through
// all Output messages until it receives a `.processingComplete` (or `.processingCancelled`). This allows the infinite stream
// to be monitored within a Task only until the current `process()` call is complete, so the filtered stream will be finite.

import RealityKit

struct UntilProcessingCompleteFilter<Base>: AsyncSequence, AsyncIteratorProtocol
        where Base: AsyncSequence, Base.Element == PhotogrammetrySession.Output {
    func makeAsyncIterator() -> UntilProcessingCompleteFilter {
        return self
    }

    typealias AsyncIterator = Self
    typealias Element = PhotogrammetrySession.Output

    private let inputSequence: Base
    private var completed: Bool = false
    private var iterator: Base.AsyncIterator

    init(input: Base) where Base.Element == Element {
        inputSequence = input
        iterator = inputSequence.makeAsyncIterator()
    }

    mutating func next() async -> Element? {
        if completed {
            return nil
        }

        guard let element = try? await iterator.next() else {
            completed = true
            return nil
        }

        if case Element.processingComplete = element {
            completed = true
        }
        if case Element.processingCancelled = element {
            completed = true
        }

        return element
    }
}

