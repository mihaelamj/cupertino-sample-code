/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements `AsyncThrowingStream` and provides blocking IO (back pressure) functionality.
*/

import Foundation
import Synchronization
import OSLog

// `AsyncIOStream` is very similar to `AsyncThrowingStream`, but extends the
// buffering policy to include `waitAfterBuffering(Int)`.
// It also constrains the stream to a single consumer to maintain simplicity.

// Alternatively, you can use `AsyncChannel` from the `async-algorithms` package,
// but that forces you to use two different stream types, depending on the buffering
// requirements.

// Note: Back pressure is of critical importance to
// eliminate processing stalls (bubbles) when feeding pipelined hardware.
// The alternative is complicated buffering that each consumer implements.

public final class AsyncIOStream<Element: Sendable, Failure>: Sendable where Failure: Error {

    // This is an extension of `AsyncThrowingStream.Continuation.BufferingPolicy`.
    public enum BufferingPolicy: Sendable {
        case unbounded
        case bufferingOldest(Int)
        case bufferingNewest(Int)
        case waitAfterBuffering(Int)
    }

    public init(bufferingPolicy: BufferingPolicy = .unbounded) where Failure == Error {

        let (stream, continuation) = AsyncThrowingStream.makeStream(of: Element.self,
                                                                   throwing: Failure.self,
                                                                   bufferingPolicy: bufferingPolicy.value)

        self.stream = stream
        self.continuation = continuation

        if case .waitAfterBuffering(_) = bufferingPolicy {
            overflowPolicy = .wait
        } else {
            overflowPolicy = .fail
        }
    }

    // The system uses this internally to track the wait policy.
    private enum OverflowPolicy: Sendable {
        case fail
        case wait
    }

    private let stream: AsyncThrowingStream<Element, Failure>
    private let continuation: AsyncThrowingStream<Element, Failure>.Continuation
    private let overflowPolicy: OverflowPolicy
    private let waiters = Mutex<[CheckedContinuation<SendResult, Failure>]>([])
}

// This embeds the continuation so that the consumer can wake waiting producers.
extension AsyncIOStream {

    public enum SendResult: Sendable {
        case pending
        case enqueued(remaining: Int)
        case dropped(Element)
        case terminated
    }

    @discardableResult
    public func send(_ element: Element) async throws -> SendResult where Failure == Error {

        guard overflowPolicy == .fail else {
            return try await blockingSend(element)
        }

        let yieldResult = continuation.yield(element)
        return SendResult(from: yieldResult)
    }

    public func finish(throwing error: Failure? = nil) {

        continuation.finish(throwing: error)

        if overflowPolicy == .wait {
            resumeWaiters(returning: SendResult.terminated)
        }
    }
}

// This is a blocking version of the send call.
private extension AsyncIOStream {

    private func blockingSend(_ element: Element) async throws -> SendResult where Failure == Error {

        var sendResult: SendResult = .pending

        while case .pending = sendResult {

            sendResult = try await withCheckedThrowingContinuation { (waiter: CheckedContinuation<SendResult, Failure>) in
                waiters.withLock {
                    let yieldResult = continuation.yield(element)

                    if case .dropped(_) = yieldResult {
                        $0.append(waiter)
                    } else {
                        waiter.resume(returning: SendResult(from: yieldResult))
                    }
                }
            }
        }

        return sendResult
    }
}

// This wakes any blocked senders.
private extension AsyncIOStream {

    private func resumeWaiters(returning result: SendResult = .pending) {

        waiters.withLock { waiters in
            for waiter in waiters {
                waiter.resume(returning: result)
            }
            waiters.removeAll()
        }
    }
}

// Implements `AsyncIteratorProtocol`.
extension AsyncIOStream: AsyncSequence where Failure == Error {

    public struct Iterator: AsyncIteratorProtocol {

            let asyncIOStream: AsyncIOStream
            var iterator: AsyncThrowingStream<Element, Failure>.Iterator

            init(from asyncIOStream: AsyncIOStream) {
                self.asyncIOStream = asyncIOStream
                iterator = asyncIOStream.stream.makeAsyncIterator()
            }

            public mutating func next() async throws -> Element? {

                let element = try await iterator.next()
                asyncIOStream.resumeWaiters()
                return element
            }

            public mutating func next(isolation actor: isolated (any Actor)?) async throws -> Element? {
                let element = try await iterator.next(isolation: actor)
                asyncIOStream.resumeWaiters()
                return element
            }
        }

    public func makeAsyncIterator() -> AsyncIOStream<Element, Failure>.Iterator {
        return Iterator(from: self)
    }
}

// This provides mapping between `AsyncIOStream.BufferingPolicy` and
// `AsyncThrowingStream.Continuation.BufferingPolicy`.
fileprivate extension AsyncIOStream.BufferingPolicy where Failure == Error {

    var value: AsyncThrowingStream<Element, Failure>.Continuation.BufferingPolicy {
        switch self {

        case .unbounded:
            return AsyncThrowingStream<Element, Failure>.Continuation.BufferingPolicy.unbounded
        case .bufferingOldest(let count):
            return AsyncThrowingStream<Element, Failure>.Continuation.BufferingPolicy.bufferingOldest(count)
        case .bufferingNewest(let count):
            return AsyncThrowingStream<Element, Failure>.Continuation.BufferingPolicy.bufferingNewest(count)
        case .waitAfterBuffering(let count):
            return AsyncThrowingStream<Element, Failure>.Continuation.BufferingPolicy.bufferingOldest(count)
        }
    }
}

// This wraps `AsyncThrowingStream.Continuation.YieldResult`.
fileprivate extension AsyncIOStream.SendResult {

    init(from yieldResult: AsyncThrowingStream<Element, Failure>.Continuation.YieldResult) {
        switch yieldResult {

        case .enqueued(remaining: let remaining):
            self = .enqueued(remaining: remaining)
        case .dropped(let element):
            self = .dropped(element)
        case .terminated:
            self = .terminated
        @unknown default:
            fatalError()
        }
    }
}
