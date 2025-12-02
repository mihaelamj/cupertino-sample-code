/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SVD image compressor class.
*/

import Accelerate
import Cocoa
import Combine

class SVDImageCompressor: ObservableObject {
    
    static let kValues: [Int] = [50, 100, 150, 200, 250, 300 ]
    
    @Published var busy = false
    
    @Published var originalImage: CGImage
    @Published var svdCompressedImage: CGImage
    
    /// The number of singular values that the app calculates.
    @Published var k: Int = 0 {
        didSet {
            busy = true
            DispatchQueue.global(qos: .userInteractive).async {
                self.applyAdjustment()
            }
        }
    }

    var sourceImageMatrix: Matrix

    init(image: NSImage) {
        guard
            let sourceCGImage = image.cgImage(forProposedRect: nil,
                                              context: nil,
                                              hints: nil),
            let sourceImageMatrix = Matrix(cgImage: sourceCGImage)  else {
            fatalError("Error initializing `SVDImageCompressor` instance.")
        }
        
        self.sourceImageMatrix = sourceImageMatrix

        if let image = sourceImageMatrix.cgImage {
            originalImage = image
        } else {
            fatalError("")
        }
   
        svdCompressedImage = sourceCGImage
        
        k = SVDImageCompressor.kValues[0]
    }
    
    /// Applies SVD compression to the image and updates the output image property with the result.
    func applyAdjustment() {
        
        if let image = try? SVDImageCompressor.compressImagePlanarF(
            source: sourceImageMatrix,
            k: k) {
            
            DispatchQueue.main.async { [self] in
                svdCompressedImage = image
                busy = false
            }
        } else {
            fatalError("Call to `compressImagePlanarF` failed.")
        }
    }
    
    /// Compresses the specified image to `k` singular values.
    ///
    /// - Parameter k: The number of singular values the sample keeps.
    static func compressImagePlanarF(source: Matrix,
                                     k: Int) throws -> CGImage? {
        
        let svdResult = Matrix.svd(a: source,
                                      k: Int(k))
        
        let imageMatrixCount = source.count
        let svdCount = svdResult.u.count + Int(k) + svdResult.vt.count
        print()
        print("Image matrix count: \(imageMatrixCount)")
        print("SVD matrices count: \(svdCount)")
        let ratio = String(format: "%.2f", Float(imageMatrixCount) / Float(svdCount))
        print(" Compression ratio: \(ratio):1")
       
        let sigma = Matrix(diagonal: svdResult.sigma.data,
                           rowCount: Int(k),
                           columnCount: Int(k))
        
        
        /// The matrix that receives `u * sigma`.
        let u_sigma = Matrix(rowCount: svdResult.u.rowCount,
                             columnCount: sigma.columnCount)
        
        Matrix.multiply(a: svdResult.u,
                        b: sigma,
                        c: u_sigma)
        
        /// The matrix that receives `u * sigma * vᵀ`.
        let u_sigma_vt = Matrix(rowCount: u_sigma.rowCount,
                                columnCount: svdResult.vt.columnCount)
        
        Matrix.multiply(a: u_sigma,
                        b: svdResult.vt,
                        c: u_sigma_vt)
        
       
        return u_sigma_vt.cgImage
        
    }
}

import simd
