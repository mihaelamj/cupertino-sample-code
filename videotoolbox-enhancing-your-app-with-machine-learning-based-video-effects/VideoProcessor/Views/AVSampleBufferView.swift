/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements `AVSampleBufferView` to show the video as it processes.
*/

import SwiftUI
import AVFoundation
import CoreFoundation
import CoreImage
import os

struct AVSampleBufferView: NSViewRepresentable {

    let inputStream: SampleBufferStream

    func makeNSView(context: Self.Context) -> AVSampleBufferUIView {
        return AVSampleBufferUIView(inputStream: inputStream)
    }

    func updateNSView(_ nsView: AVSampleBufferUIView, context: Context) {
    }
}

class AVSampleBufferUIView: NSView {

    var inputStream: SampleBufferStream
    let displayLayer: AVSampleBufferDisplayLayer
    let sampleBufferRenderer: AVSampleBufferVideoRenderer

    init(inputStream: SampleBufferStream) {

        self.inputStream = inputStream
        displayLayer = AVSampleBufferDisplayLayer()
        sampleBufferRenderer = displayLayer.sampleBufferRenderer

        super.init(frame: .zero)

        // Set the `AVSampleBuffer` playback rate to `1.0` to play the video.
        let cmTimebasePointer = UnsafeMutablePointer<CMTimebase?>.allocate(capacity: 1)
        CMTimebaseCreateWithSourceClock(allocator: kCFAllocatorDefault, sourceClock: CMClockGetHostTimeClock(), timebaseOut:
                                            cmTimebasePointer)
        displayLayer.controlTimebase = cmTimebasePointer.pointee
        CMTimebaseSetTime(displayLayer.controlTimebase!, time: .zero)
        CMTimebaseSetRate(displayLayer.controlTimebase!, rate: 1.0)
        
        self.layer = displayLayer

        self.run()
    }

    required init?(coder: NSCoder) { return nil }

    var task: Task<Void, Never>?
    func run() {

        task?.cancel()

        self.task = Task.detached {
            do {
                for try await sampleBuffer in await self.inputStream {
                    await self.process(sampleBuffer: sampleBuffer.cmSampleBuffer)
                }
            } catch {
                logger.error("AVSampleBufferUIView failed with error: \(error)")
            }
        }
    }

    let dispatchQueue = DispatchQueue(label: "AVSampleBufferUIView")

    func process(sampleBuffer: CMSampleBuffer) async {

        nonisolated(unsafe) let sampleBufferRenderer = sampleBufferRenderer

        if sampleBufferRenderer.isReadyForMoreMediaData == false {
            await withCheckedContinuation { continuation in

                sampleBufferRenderer.requestMediaDataWhenReady(on: dispatchQueue) {
                    sampleBufferRenderer.stopRequestingMediaData()
                    continuation.resume()
                }
            }
        }

        sampleBufferRenderer.enqueue(sampleBuffer)
    }
}
