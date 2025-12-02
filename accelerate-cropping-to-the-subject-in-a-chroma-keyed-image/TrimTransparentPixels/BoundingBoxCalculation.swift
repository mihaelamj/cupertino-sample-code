/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The transparent pixel-trimming function file.
*/


import Accelerate

extension ImageProvider {
    
    /// - Tag: boundingBoxForNonTransparentPixels
    /// Returns the smallest bounding box by trimming the transparent pixels.
    static func boundingBoxForNonTransparentPixels(alphaBuffer: vImage.PixelBuffer<vImage.PlanarF>) -> CGRect {
        
        var top = 0
        var bottom = alphaBuffer.height
        var left = 0
        var right = alphaBuffer.width
        
        alphaBuffer.withUnsafeBufferPointer { alphaPointer in
            
            let rowStride = alphaBuffer.rowStride
            
            // Find the bounding box top.
            for i in 0 ..< alphaBuffer.height {
                
                let start = alphaPointer.baseAddress?.advanced(by: i * rowStride)
                let row = UnsafeBufferPointer<Float>(start: start, count: alphaBuffer.width)
                let sum = vDSP.sum(row)
                
                if sum != 0 {
                    top = i
                    break
                }
            }
            
            // Find the bounding box bottom.
            for i in stride(from: alphaBuffer.height - 1, through: top, by: -1) {
                
                let start = alphaPointer.baseAddress?.advanced(by: i * rowStride)
                let row = UnsafeBufferPointer<Float>(start: start, count: alphaBuffer.width)
                let sum = vDSP.sum(row)
                
                if sum != 0 {
                    bottom = i
                    break
                }
            }
            
            let height = bottom - top
            
            // Find the bounding box left.
            for i in 0 ..< alphaBuffer.width {
                
                let columnStart = alphaPointer.baseAddress!.advanced(by: i + (top * rowStride))
                
                var sum = Float()
                
                vDSP_sve(columnStart, rowStride, &sum, vDSP_Length(height))
                
                if sum != 0 {
                    left = i
                    break
                }
            }
            
            // Find the bounding box right.
            for i in stride(from: alphaBuffer.width - 1, through: 0, by: -1) {
                
                let columnStart = alphaPointer.baseAddress!.advanced(by: i + (top * rowStride))
                
                var sum = Float()
                
                vDSP_sve(columnStart, rowStride, &sum, vDSP_Length(height))
                
                if sum != 0 {
                    right = i
                    break
                }
            }
        } // Ends `alphaBuffer.withUnsafeBufferPointer { alphaPointer in`.
        
        return CGRect(x: left,
                      y: top,
                      width: right - left,
                      height: bottom - top)
    }
    
}
