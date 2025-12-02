/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class that provides histogram ends-in contrast stretching to an image.
*/

import Accelerate
import Combine
import Cocoa

class ContrastStretcher: ObservableObject {
    
    let context = CIContext()
    let ciImage: CIImage
    
    let sourceImage = #imageLiteral(resourceName: "Flowers_2.jpg").cgImage(
        forProposedRect: nil,
        context: nil,
        hints: nil)!
    
    @Published var outputImage: CGImage!
    
    @Published var percentLow: Double = 0 {
        didSet {
            if percentLow + percentHigh > 100 {
                percentHigh = 100 - percentLow
            }
            applyEndsInContrastStretch()
        }
    }
    
    @Published var percentHigh: Double = 0 {
        didSet {
            if percentLow + percentHigh > 100 {
                percentLow = 100 - percentHigh
            }
            applyEndsInContrastStretch()
        }
    }
    
    init() {
        ciImage = CIImage(cgImage: sourceImage)
        
        applyEndsInContrastStretch()
    }
    
    func applyEndsInContrastStretch() {
        let ciResult = try? ContrastStretchImageProcessorKernel.apply(
            withExtent: ciImage.extent,
            inputs: [ciImage],
            arguments: ["percentLow": Int(percentLow),
                        "percentHigh": Int(percentHigh)])
        
        if let ciResult = ciResult,
           let cgResult = context.createCGImage(ciResult,
                                                from: ciResult.extent) {
            outputImage = cgResult
        }
    }
}
