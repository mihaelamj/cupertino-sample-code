/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This code provides the Vision routines for saliency analysis on an image or buffer.
*/

import Foundation
import Vision
import CoreVideo
import CoreImage

public enum SaliencyType: Int {
    case attentionBased = 0
    case objectnessBased
}

public enum ViewMode: Int {
    case combined = 0
    case rectsOnly
    case maskOnly
}

public func processSaliency(_ type: SaliencyType,
                            on pixelBuffer: CVPixelBuffer,
                            orientation: CGImagePropertyOrientation) -> VNSaliencyImageObservation? {
    
    let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
    return processSaliencyRequestOnHandler(type, on: requestHandler)
}

public func processSaliency(_ type: SaliencyType,
                            on imageURL: URL) -> VNSaliencyImageObservation? {
    
    let requestHandler = VNImageRequestHandler(url: imageURL, options: [:])
    return processSaliencyRequestOnHandler(type, on: requestHandler)
}

public func createHeatMapMask(from observation: VNSaliencyImageObservation) -> CGImage? {
    let pixelBuffer = observation.pixelBuffer
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    let vector = CIVector(x: 0, y: 0, z: 0, w: 1)
    let saliencyImage = ciImage.applyingFilter("CIColorMatrix", parameters: ["inputBVector": vector])
    return CIContext().createCGImage(saliencyImage, from: saliencyImage.extent)
}

public func createSalientObjectsBoundingBoxPath(from observation: VNSaliencyImageObservation, transform: CGAffineTransform) -> CGPath {
    let path = CGMutablePath()
    if let salientObjects = observation.salientObjects {
        for object in salientObjects {
            let bbox = object.boundingBox
            path.addRect(bbox, transform: transform)
        }
    }
    return path
}

private func processSaliencyRequestOnHandler(_ type: SaliencyType,
                                             on requestHandler: VNImageRequestHandler) -> VNSaliencyImageObservation? {
    
    let request: VNRequest
    switch type {
    case .attentionBased:
        request = VNGenerateAttentionBasedSaliencyImageRequest()
    case .objectnessBased:
        request = VNGenerateObjectnessBasedSaliencyImageRequest()
    }
    try? requestHandler.perform([request])
    
    return request.results?.first as? VNSaliencyImageObservation
}
