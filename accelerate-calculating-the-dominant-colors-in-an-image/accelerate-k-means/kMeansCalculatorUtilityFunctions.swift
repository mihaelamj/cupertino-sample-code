/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utility functions.
*/


import Accelerate
import QuickLookThumbnailing
import Cocoa

extension KMeansCalculator {
    
    /// Populates the `distances` memory with the distance squared between each centroid and each color.
    func populateDistances() {
        for centroid in centroids.enumerated() {
            distanceSquared(x0: greenStorage.baseAddress!, x1: centroid.element.green,
                            y0: blueStorage.baseAddress!, y1: centroid.element.blue,
                            z0: redStorage.baseAddress!, z1: centroid.element.red,
                            n: greenStorage.count,
                            result: distances.baseAddress!.advanced(by: dimension * dimension * centroid.offset))
        }
    }
    
    /// Returns the index of the closest centroid for each color.
    func makeCentroidIndices() -> [Int32] {
        let distancesDescriptor = BNNSNDArrayDescriptor(
            data: distances,
            shape: .matrixRowMajor(dimension * dimension, k))!
        
        let reductionLayer = BNNS.ReductionLayer(function: .argMin,
                                                 input: distancesDescriptor,
                                                 output: centroidIndicesDescriptor,
                                                 weights: nil)
        
        try! reductionLayer?.apply(batchSize: 1,
                                   input: distancesDescriptor,
                                   output: centroidIndicesDescriptor)
        
        return centroidIndicesDescriptor.makeArray(of: Int32.self)!
    }
    
    /// A 1 x 1 Core Graphics image.
    static var emptyCGImage: CGImage = {
        let buffer = vImage.PixelBuffer(
            pixelValues: [0],
            size: .init(width: 1, height: 1),
            pixelFormat: vImage.Planar8.self)
        
        let fmt = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 8 ,
            colorSpace: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            renderingIntent: .defaultIntent)
        
        return buffer.makeCGImage(cgImageFormat: fmt!)!
    }()
    
    /// Generates a thumbnails for a specified resource.
    ///
    /// See: [Creating Quick Look Thumbnails to Preview Files in Your App](https://developer.apple.com/documentation/quicklookthumbnailing/creating_quick_look_thumbnails_to_preview_files_in_your_app)
    func generateThumbnailRepresentations(forResource resource: String,
                                          withExtension ext: String) {
        
        // Set up the parameters of the request.
        guard let url = Bundle.main.url(forResource: resource,
                                        withExtension: ext) else {
            
            // Handle the error case.
            assert(false, "The URL can't be nil")
            return
        }
        let size: CGSize = CGSize(width: 100, height: 100)
        let scale = NSScreen.main?.backingScaleFactor ?? 1
        
        // Create the thumbnail request.
        let request = QLThumbnailGenerator.Request(fileAt: url,
                                                   size: size,
                                                   scale: scale,
                                                   representationTypes: .thumbnail)
        
        // Retrieve the singleton instance of the thumbnail generator and generate the thumbnails.
        let generator = QLThumbnailGenerator.shared
        generator.generateRepresentations(for: request) { (thumbnail, type, error) in
            DispatchQueue.main.async {
                if let thumbnail = thumbnail {
                    let x = Thumbnail(thumbnail: thumbnail.cgImage,
                                        resource: resource,
                                        ext: ext)
                    self.sourceImages.append(x)
                }
            }
        }
    }
    
    func weightedRandomIndex(_ weights: UnsafeMutableBufferPointer<Float>) -> Int {
        var outputDescriptor = BNNSNDArrayDescriptor.allocateUninitialized(
            scalarType: Float.self,
            shape: .vector(1))
  
        var probabilities = BNNSNDArrayDescriptor(
            data: weights,
            shape: .vector(weights.count))!
        
        let randomGenerator = BNNSCreateRandomGenerator(
            BNNSRandomGeneratorMethodAES_CTR,
            nil)
        
        BNNSRandomFillCategoricalFloat(
            randomGenerator, &outputDescriptor, &probabilities, false)
        
        defer {
            BNNSDestroyRandomGenerator(randomGenerator)
            outputDescriptor.deallocate()
        }
        
        return Int(outputDescriptor.makeArray(of: Float.self)!.first!)
    }
    
    func distanceSquared(
        x0: UnsafePointer<Float>, x1: Float,
        y0: UnsafePointer<Float>, y1: Float,
        z0: UnsafePointer<Float>, z1: Float,
        n: Int,
        result: UnsafeMutablePointer<Float>) {
            
            var x = subtract(a: x0, b: x1, n: n)
            vDSP.square(x, result: &x)
            
            var y = subtract(a: y0, b: y1, n: n)
            vDSP.square(y, result: &y)
            
            var z = subtract(a: z0, b: z1, n: n)
            vDSP.square(z, result: &z)
            
            vDSP_vadd(x, 1, y, 1, result, 1, vDSP_Length(n))
            vDSP_vadd(result, 1, z, 1, result, 1, vDSP_Length(n))
        }
    
    func subtract(a: UnsafePointer<Float>, b: Float, n: Int) -> [Float] {
        return [Float](unsafeUninitializedCapacity: n) {
            buffer, count in
            
            vDSP_vsub(a, 1,
                      [b], 0,
                      buffer.baseAddress!, 1,
                      vDSP_Length(n))
            
            count = n
        }
    }
    
    func saturate<T: FloatingPoint>(_ x: T) -> T {
        return min(max(0, x), 1)
    }
}
