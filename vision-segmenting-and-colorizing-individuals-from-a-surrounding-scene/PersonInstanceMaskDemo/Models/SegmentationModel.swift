/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The model that runs the segmentation APIs and returns the results.
*/

import CoreImage.CIFilterBuiltins
import CoreVideo
import Foundation
import SwiftUI
import Vision

class SegmentationModel: ObservableObject {
    
    enum RequestState {
        case loading
        case success
        case failure
    }

    @Published var segmentedImage: UIImage?
    @Published var showWarning: Bool = false
    var selectedSegments: IndexSet = []
    var segmentationCount = 0
    var segmentationResults: SegmentationResults?
    var baseImage: CIImage?
    static let colors: [UIColor] = [.darkGray, .blue, .red, .green, .yellow]
    
    func runSegmentationRequestOnImage(_ image: CIImage) async -> RequestState {
        // Before running VNGeneratePersonInstanceMaskRequest, first count the number of people.
        // If there are more than 4 people in an image, use VNPersonSegmentationRequest instead.
        let request: VNImageBasedRequest
        let numFaces = await countFaces(image: image)
        if numFaces <= 4 {
            request = VNGeneratePersonInstanceMaskRequest()
        } else {
            request = VNGeneratePersonSegmentationRequest()
        }

        // Set up and run the request.
        let requestHandler = VNImageRequestHandler(ciImage: image)
        self.baseImage = image
        do {
            try requestHandler.perform([request])
            
            // Get the segmentation results from the request.
            switch request.results?.first {
            case let buffer as VNPixelBufferObservation:
                segmentationResults = PersonSegmentationResults(results: buffer)
                selectedSegments = [1]
            case let instanceMask as VNInstanceMaskObservation:
                segmentationResults = InstanceMaskResults(results: instanceMask, requestHandler: requestHandler)
                selectedSegments = instanceMask.allInstances
            default:
                break
            }
            let segmentedImage = await segmentationResults?.generateSegmentedImage(baseImage: image, selectedSegments: selectedSegments)
            
            Task { @MainActor in
                // Update the UI.
                if let results = segmentationResults {
                    self.segmentationCount = results.numSegments
                }
                self.segmentedImage = segmentedImage ?? UIImage(cgImage: CIContext().createCGImage(image, from: image.extent)!)
                self.showWarning = segmentationResults is PersonSegmentationResults
            }
        } catch {
            print("Unable to perform the request: \(error).")
            return .failure
        }
        return .success
    }
    
    // Selects or de-selects the segment at the given index.
    func toggleSegment(index: Int) async {
        if selectedSegments.contains(index) {
            selectedSegments.remove(index)
        } else {
            selectedSegments.insert(index)
        }
        let segmentedImage = await segmentationResults?.generateSegmentedImage(baseImage: baseImage!, selectedSegments: selectedSegments)
        Task { @MainActor in
            self.segmentedImage = segmentedImage
        }
    }
    
    // Selects or de-selects the segment where a tap occurs.
    func toggleSegmentAtLocation(_ location: CGPoint, extent: CGSize) async {
        let normalizedLocation = VNNormalizedPointForImagePoint(location, Int(extent.width), Int(extent.height))
        let segmentIndex = segmentAtLocation(normalizedLocation)
        await toggleSegment(index: segmentIndex)
    }
    
    // Returns whether or not a given segment is selected.
    func isSelected(_ index: Int) -> Bool {
        return selectedSegments.contains(index)
    }
    // Returns the number of people in the image.
    private func countFaces(image: CIImage) async -> Int {
        // Approximate the number of people in the image.
        let request = VNDetectFaceRectanglesRequest()
        let requestHandler = VNImageRequestHandler(ciImage: image)
        do {
            try requestHandler.perform([request])
            if let results = request.results {
                return results.count
            }
        } catch {
            print("Unable to perform face detection: \(error).")
        }
        return 0
    }

    // Returns which segment a point within the image belongs to.
    private func segmentAtLocation(_ location: CGPoint) -> Int {
        guard let buffer = segmentationResults?.segmentationMask else {
            return 0
        }
        // Lock PixelBuffer before reading.
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
        
        // Convert normalized point location to a buffer row and column.
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let bufferPoint = VNImagePointForNormalizedPoint(location, width, height)
        let row: Int = min(height, max(0, Int(bufferPoint.y)))
        let col: Int = min(width, max(0, Int(bufferPoint.x)))
        
        // Read the buffer pixel from memory.
        let baseAddress = CVPixelBufferGetBaseAddress(buffer)?.assumingMemoryBound(to: UInt8.self)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        let pixelValue = baseAddress![col + bytesPerRow * row]
        let segment = segmentationResults!.segmentForPixelValue(pixelValue)
        
        // Unlock the buffer after reading completes.
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
        
        return segment
    }
}
