/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The models that generate a segmented image.
*/

import Foundation
import SwiftUI
import Vision

protocol SegmentationResults {
    var segmentationMask: CVPixelBuffer { get set }
    var numSegments: Int { get set }
    func generateSegmentedImage(baseImage: CIImage, selectedSegments: IndexSet) async -> UIImage
    func segmentForPixelValue(_ value: UInt8) -> Int
}

// Class that generates segmented images for up to four faces.

class InstanceMaskResults: SegmentationResults {
    
    var numSegments: Int
    var segmentationMask: CVPixelBuffer
    var instanceMasks: VNInstanceMaskObservation
    var requestHandler: VNImageRequestHandler
    
    init(results: VNInstanceMaskObservation, requestHandler: VNImageRequestHandler) {
        self.instanceMasks = results
        self.segmentationMask = results.instanceMask
        self.numSegments = results.allInstances.count + 1
        self.requestHandler = requestHandler
    }
    
    // Generate image with selected segments highlighted in various colors.
    func generateSegmentedImage(baseImage: CIImage, selectedSegments: IndexSet) async -> UIImage {
        var image = baseImage
        for index in selectedSegments {
            do {
                let maskPixelBuffer = try instanceMasks.generateScaledMaskForImage(forInstances: [index], from: requestHandler)
                let maskImage = CIImage(cvPixelBuffer: maskPixelBuffer)
                image = blendImageWithMask(image: image, mask: maskImage, color: SegmentationModel.colors[index])
            } catch {
                print("Error generating mask: \(error).")
            }
        }
        return UIImage(cgImage: CIContext().createCGImage(image, from: image.extent)!)
    }
    
    // Get the segment index that corresponds to the given pixel value in the instance mask pixel buffer.
    func segmentForPixelValue(_ value: UInt8) -> Int {
        return Int(value)
    }
}

// Class that generates segmented images for more than four faces.

class PersonSegmentationResults: SegmentationResults {
    var numSegments: Int
    var segmentationMask: CVPixelBuffer
    
    init(results: VNPixelBufferObservation) {
        numSegments = 2
        segmentationMask = results.pixelBuffer
    }
    
    // Generate image with selected segments highlighted in various colors.
    func generateSegmentedImage(baseImage: CIImage, selectedSegments: IndexSet) async -> UIImage {
        var maskImage = CIImage(cvPixelBuffer: segmentationMask)
        // Scale mask to image size.
        let scaleX = baseImage.extent.width / maskImage.extent.width
        let scaleY = baseImage.extent.height / maskImage.extent.height
        maskImage = maskImage.transformed(by: .init(scaleX: scaleX, y: scaleY))
        
        var segmentedImage = baseImage
        if selectedSegments.contains(1) {
            // Foreground is selected.
            segmentedImage = blendImageWithMask(image: baseImage, mask: maskImage, color: SegmentationModel.colors[1])
        }
        if selectedSegments.contains(0) {
            // Background is selected.
            let blendFilter = CIFilter.blendWithMask()
            blendFilter.inputImage = baseImage
            blendFilter.backgroundImage = CIImage(color: CIColor(color: SegmentationModel.colors[0])).cropped(to: baseImage.extent)
            blendFilter.maskImage = maskImage
            segmentedImage = blendFilter.outputImage!
        }
        return UIImage(cgImage: CIContext().createCGImage(segmentedImage, from: segmentedImage.extent)!)
    }

    // Get the segment index that corresponds to the given pixel value in the segmentation pixel buffer.
    func segmentForPixelValue(_ value: UInt8) -> Int {
        return value > 0 ? 1 : 0
    }
}

// Apply mask of given color to an image.
func blendImageWithMask(image: CIImage, mask: CIImage, color: UIColor) -> CIImage {
    let blendFilter = CIFilter.blendWithMask()
    blendFilter.inputImage = CIImage(color: CIColor(color: color))
    blendFilter.backgroundImage = image
    blendFilter.maskImage = mask
    return blendFilter.outputImage!
}
