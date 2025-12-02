/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data model that computes colors from an image using the k-means algorithm,
  which finds the k dominant colors by k random centroids.
*/

import Foundation
import Accelerate
import simd
import SwiftUI

nonisolated final class ColorExtractor {
    private let k = 4

    static let dimension = 256
    static let channelCount = 3
    static let tolerance = 10

    /// The current source image.
    private var sourceImage: CGImage = {
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

    /// The Core Graphics image format.
    private var rgbImageFormat = vImage_CGImageFormat(
        bitsPerComponent: 32,
        bitsPerPixel: 32 * 3,
        colorSpace: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo(
            rawValue: kCGBitmapByteOrder32Host.rawValue |
            CGBitmapInfo.floatComponents.rawValue |
            CGImageAlphaInfo.none.rawValue))!

    /// Storage for a matrix with `dimension * dimension` columns and `k` rows that stores the
    /// distances squared of each pixel color for each centroid.
    private var distances: UnsafeMutableBufferPointer<Float>!

    /// The storage and pixel buffer for each red value.
    private let redStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
    private let redBuffer: vImage.PixelBuffer<vImage.PlanarF>

    /// The storage and pixel buffer for each green value.
    private let greenStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
    private let greenBuffer: vImage.PixelBuffer<vImage.PlanarF>

    /// The storage and pixel buffer for each blue value.
    private let blueStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
    private let blueBuffer: vImage.PixelBuffer<vImage.PlanarF>

    /// The storage and pixel buffer for each quantized red value.
    private let redQuantizedStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
    private let redQuantizedBuffer: vImage.PixelBuffer<vImage.PlanarF>

    /// The storage and pixel buffer for each quantized green value.
    private let greenQuantizedStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
    private let greenQuantizedBuffer: vImage.PixelBuffer<vImage.PlanarF>

    /// The storage and pixel buffer for each quantized blue value.
    private let blueQuantizedStorage = UnsafeMutableBufferPointer<Float>.allocate(capacity: dimension * dimension)
    private let blueQuantizedBuffer: vImage.PixelBuffer<vImage.PlanarF>

    /// The array of `k` centroids.
    private var centroids = [Centroid]()

    /// The BNNS array descriptor that receives the centroid indices.
    private let centroidIndicesDescriptor: BNNSNDArrayDescriptor

    private let maximumIterations = 50
    private var iterationCount = 0

    /// - Tag: Life cycle
    init() {
        redBuffer = vImage.PixelBuffer<vImage.PlanarF>(
            data: redStorage.baseAddress!,
            width: ColorExtractor.dimension,
            height: ColorExtractor.dimension,
            byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride)

        greenBuffer = vImage.PixelBuffer<vImage.PlanarF>(
            data: greenStorage.baseAddress!,
            width: ColorExtractor.dimension,
            height: ColorExtractor.dimension,
            byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride)

        blueBuffer = vImage.PixelBuffer<vImage.PlanarF>(
            data: blueStorage.baseAddress!,
            width: ColorExtractor.dimension,
            height: ColorExtractor.dimension,
            byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride)

        redQuantizedBuffer = vImage.PixelBuffer<vImage.PlanarF>(
            data: redQuantizedStorage.baseAddress!,
            width: ColorExtractor.dimension,
            height: ColorExtractor.dimension,
            byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride)

        greenQuantizedBuffer = vImage.PixelBuffer<vImage.PlanarF>(
            data: greenQuantizedStorage.baseAddress!,
            width: ColorExtractor.dimension,
            height: ColorExtractor.dimension,
            byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride)

        blueQuantizedBuffer = vImage.PixelBuffer<vImage.PlanarF>(
            data: blueQuantizedStorage.baseAddress!,
            width: ColorExtractor.dimension,
            height: ColorExtractor.dimension,
            byteCountPerRow: ColorExtractor.dimension * MemoryLayout<Float>.stride)

        centroidIndicesDescriptor = BNNSNDArrayDescriptor.allocateUninitialized(
            scalarType: Int32.self,
            shape: .matrixRowMajor(ColorExtractor.dimension * ColorExtractor.dimension, 1))

        allocateDistancesBuffer()
    }

    deinit {
        redStorage.deallocate()
        greenStorage.deallocate()
        blueStorage.deallocate()

        redQuantizedStorage.deallocate()
        greenQuantizedStorage.deallocate()
        blueQuantizedStorage.deallocate()

        centroidIndicesDescriptor.deallocate()
        distances.deallocate()
    }

    /// Calculates k-means for the selected thumbnail.
    func extractColors(from data: Data) -> PhotoColorScheme? {
        guard let image = cgImage(from: data) else { return nil }

        allocateDistancesBuffer()
        sourceImage = image

        let rgbSources: [vImage.PixelBuffer<vImage.PlanarF>] = try! vImage.PixelBuffer<vImage.InterleavedFx3>(
            cgImage: sourceImage,
            cgImageFormat: &rgbImageFormat).planarBuffers()

        rgbSources[0].scale(destination: redBuffer)
        rgbSources[1].scale(destination: greenBuffer)
        rgbSources[2].scale(destination: blueBuffer)

        initializeCentroids()

        var converged = false
        var iterationCount = 0

        while !converged && iterationCount < maximumIterations {
            converged = updateCentroids()
            iterationCount += 1
        }

        return .init(colors: centroids.map {
            Color(red: CGFloat($0.red), green: CGFloat($0.green), blue: CGFloat($0.blue))
        })
    }
}

private nonisolated extension ColorExtractor {
    /// Allocates the memory required for the distances matrix.
    func allocateDistancesBuffer() {
        if distances != nil {
            distances.deallocate()
        }
        distances = UnsafeMutableBufferPointer<Float>.allocate(capacity: ColorExtractor.dimension * ColorExtractor.dimension * k)
    }

    func cgImage(from data: Data) -> CGImage? {
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }

        return CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    }

    /// - Tag: initializeCentroids
    func initializeCentroids() {
        centroids.removeAll()

        let randomIndex = Int.random(in: 0 ..< ColorExtractor.dimension * ColorExtractor.dimension)
        centroids.append(Centroid(red: redStorage[randomIndex],
                                  green: greenStorage[randomIndex],
                                  blue: blueStorage[randomIndex]))

        // Use the first row of the `distances` buffer as temporary storage.
        let tmp = UnsafeMutableBufferPointer(start: distances.baseAddress!,
                                             count: ColorExtractor.dimension * ColorExtractor.dimension)
        for i in 1 ..< k {
            distanceSquared(x0: greenStorage.baseAddress!, x1: centroids[i - 1].green,
                            y0: blueStorage.baseAddress!, y1: centroids[i - 1].blue,
                            z0: redStorage.baseAddress!, z1: centroids[i - 1].red,
                            n: greenStorage.count,
                            result: tmp.baseAddress!)

            let randomIndex = weightedRandomIndex(tmp)

            centroids.append(Centroid(red: redStorage[randomIndex],
                                      green: greenStorage[randomIndex],
                                      blue: blueStorage[randomIndex]))
        }
    }

    /// Updates centroids and returns `true` when the pixel counts don't change
    /// (that is, the solution converges).
    ///
    /// 1. Create k random centroids that the system selects from the RGB colors in an image.
    /// 2. Create a distances matrix that has pixel-count columns and k rows.
    /// 3. For each centroid, populate the corresponding row in the distances matrix with the distance squared
    /// between it and each matrix.
    /// 4. Use the BNNS reduction `argMin` on the distances matrix to create a vector with pixel-count elements.
    /// Each element in the vector is the centroid that's the closest color to the corresponding pixel.
    /// 5. For each centroid, use BNNS gather to create a vector for each RGB channel of the pixel
    /// colors for that centroid. Compute the mean value of that vector and set the centroid color to that average.
    /// 6. Repeat steps 3, 4, and 5 until the solution converges.
    /// - Tag: updateCentroids
    func updateCentroids() -> Bool {
        // The pixel counts per centroid before this iteration.
        let pixelCounts = centroids.map { return $0.pixelCount }

        populateDistances()
        let centroidIndices = makeCentroidIndices()

        for centroid in centroids.enumerated() {

            // The indices into the red, green, and blue descriptors for this centroid.
            let indices = centroidIndices.enumerated().filter {
                $0.element == centroid.offset
            }.map {
                // `vDSP.gather` uses one-based indices.
                UInt($0.offset + 1)
            }

            centroids[centroid.offset].pixelCount = indices.count

            if !indices.isEmpty {
                let gatheredRed = vDSP.gather(redStorage,
                                              indices: indices)

                let gatheredGreen = vDSP.gather(greenStorage,
                                                indices: indices)

                let gatheredBlue = vDSP.gather(blueStorage,
                                               indices: indices)

                centroids[centroid.offset].red = vDSP.mean(gatheredRed)
                centroids[centroid.offset].green = vDSP.mean(gatheredGreen)
                centroids[centroid.offset].blue = vDSP.mean(gatheredBlue)
            }
        }

        return pixelCounts.elementsEqual(centroids.map { return $0.pixelCount }) { a, b in
            return abs(a - b) < ColorExtractor.tolerance
        }
    }

    func populateDistances() {
        for centroid in centroids.enumerated() {
            distanceSquared(x0: greenStorage.baseAddress!, x1: centroid.element.green,
                            y0: blueStorage.baseAddress!, y1: centroid.element.blue,
                            z0: redStorage.baseAddress!, z1: centroid.element.red,
                            n: greenStorage.count,
                            result: distances.baseAddress!.advanced(by: ColorExtractor.dimension * ColorExtractor.dimension * centroid.offset))
        }
    }

    /// Returns the index of the closest centroid for each color.
    func makeCentroidIndices() -> [Int32] {
        let distancesDescriptor = BNNSNDArrayDescriptor(
            data: distances,
            shape: .matrixRowMajor(ColorExtractor.dimension * ColorExtractor.dimension, k))!

        try! BNNS.applyReduction(.argMin, input: distancesDescriptor, output: centroidIndicesDescriptor, weights: nil)

        return centroidIndicesDescriptor.makeArray(of: Int32.self)!
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

        let result = Int(outputDescriptor.makeArray(of: Float.self)!.first!)
        BNNSDestroyRandomGenerator(randomGenerator)
        outputDescriptor.deallocate()

        return result
    }

    private func distanceSquared(
        x0: UnsafePointer<Float>, x1: Float,
        y0: UnsafePointer<Float>, y1: Float,
        z0: UnsafePointer<Float>, z1: Float,
        n: Int,
        result: UnsafeMutablePointer<Float>
    ) {
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
        min(max(0, x), 1)
    }
}

/// - Tag: Centroid
private extension ColorExtractor {
    /// A structure that represents a centroid.
    struct Centroid {
        /// The red channel value.
        var red: Float

        /// The green channel value.
        var green: Float

        /// The blue channel value.
        var blue: Float

        /// The number of assigned pixels for this cluster center.
        var pixelCount: Int = 0
    }
}
