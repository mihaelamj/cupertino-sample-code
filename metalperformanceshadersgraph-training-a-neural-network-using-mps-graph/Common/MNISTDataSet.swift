/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience wrapper to work with dataset
*/
    
import Foundation
import zlib

import MetalPerformanceShaders

let MNISTImageMetadataPrefixSize = 16
let MNISTLabelsMetadataPrefixSize = 8
let MNISTSize = 28
let MNISTNumClasses = 10

extension Data {
    
    func gunzippedData() -> Data {
        var stream = z_stream()
        var status: Int32
        
        status = inflateInit2_(&stream, 47, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        
        var data = Data(capacity: self.count * 2)
        repeat {
            if Int(stream.total_out) >= data.count {
                data.count += self.count / 2
            }
            
            let inputCount = self.count
            let outputCount = data.count
            
            self.withUnsafeBytes { (inputPointer: UnsafeRawBufferPointer) in
                stream.next_in =
                    UnsafeMutablePointer<Bytef>(mutating: inputPointer.bindMemory(to: Bytef.self).baseAddress!).advanced(by: Int(stream.total_in))
                stream.avail_in = uint(inputCount) - uInt(stream.total_in)
                
                data.withUnsafeMutableBytes { (outputPointer: UnsafeMutableRawBufferPointer) in
                    stream.next_out = outputPointer.bindMemory(to: Bytef.self).baseAddress!.advanced(by: Int(stream.total_out))
                    stream.avail_out = uInt(outputCount) - uInt(stream.total_out)
                    
                    status = inflate(&stream, Z_SYNC_FLUSH)
                    
                    stream.next_out = nil
                }
                
                stream.next_in = nil
            }
            
        } while status == Z_OK
        
        if inflateEnd(&stream) == Z_OK, status == Z_STREAM_END {
            data.count = Int(stream.total_out)
        }
        
        return data
    }
}

class MNISTDataSet {
    
    var totalNumberOfTestImages: UInt = 0
    var sizeTestImages: UInt = 0
    var sizeTestLabels: UInt = 0
    var dataTestImage: Data?
    var dataTestLabel: Data?
    
    var totalNumberOfTrainImages: UInt = 0
    var sizeTrainImages: UInt = 0
    var sizeTrainLabels: UInt = 0
    var dataTrainImage: Data?
    var dataTrainLabel: Data?
    
    var seed = 0

    func downloadFile(stringURL: String) -> Data? {
        NSLog("Downloading %@", stringURL)

        let url = URL(string: stringURL)!
        let urlData = NSData(contentsOf: url)
        
        var uncompressedData: Data? = nil
        
        if urlData != nil {
            NSLog("Downloaded %@", stringURL)
            
            var cacheURL: URL
            do {
                cacheURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            } catch {
                NSLog("Could not build URL for cache directory")
                return nil
            }
                    
            let fileURL = cacheURL.appendingPathComponent(NSString(string: stringURL).lastPathComponent)
            do {
                try urlData!.write(to: fileURL, options: NSData.WritingOptions.atomicWrite)
            } catch {
                NSLog("Failed to write compressed data")
                return nil
            }
            
            uncompressedData = (urlData! as Data).gunzippedData()
            if uncompressedData != nil {
                let filePath = NSString(string: stringURL).lastPathComponent
                let fileName = NSString(string: filePath).deletingPathExtension
                
                let dataFileURL = cacheURL.appendingPathComponent(String(format: "%@.data", fileName))

                do {
                    try uncompressedData!.write(to: dataFileURL)
                } catch {
                    NSLog("Failed to write uncompressed data")
                    return nil
                }
                return uncompressedData
            }
        } else {
            NSLog("Downloading %@ failed!", stringURL)
        }
        return nil
    }
    
    init() {
        
        // Saved url for the mnist dataset from online.
        let trainImagesURL = "http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz"
        let trainLabelsURL = "http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz"
        let testImagesURL = "http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz"
        let testLabelsURL = "http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz"
        
        var cacheURL: URL
        do {
            cacheURL = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        } catch {
            NSLog("Could not build URL for cache directory")
            return
        }
        
        let imageTrainURL = cacheURL.appendingPathComponent("train-images-idx3-ubyte.data")
        let labelTrainURL = cacheURL.appendingPathComponent("train-labels-idx1-ubyte.data")
        let imageTestURL = cacheURL.appendingPathComponent("t10k-images-idx3-ubyte.data")
        let labelTestURL = cacheURL.appendingPathComponent("t10k-labels-idx1-ubyte.data")

        do {
            try dataTrainImage = Data(contentsOf: imageTrainURL)
        } catch {
            dataTrainImage = downloadFile(stringURL: trainImagesURL)!
        }
        
        do {
            try dataTrainLabel = Data(contentsOf: labelTrainURL)
        } catch {
            dataTrainLabel = downloadFile(stringURL: trainLabelsURL)!
        }

        do {
            try dataTestImage = Data(contentsOf: imageTestURL)
        } catch {
            dataTestImage = downloadFile(stringURL: testImagesURL)!
        }
        
        do {
            try dataTestLabel = Data(contentsOf: labelTestURL)
        } catch {
            dataTestLabel = downloadFile(stringURL: testLabelsURL)!
        }
        
        sizeTrainLabels = UInt(dataTrainLabel!.count)
        sizeTrainImages = UInt(dataTrainImage!.count)
        totalNumberOfTrainImages = sizeTrainLabels - UInt(MNISTLabelsMetadataPrefixSize)

        sizeTestLabels = UInt(dataTestLabel!.count)
        sizeTestImages = UInt(dataTestImage!.count)
        totalNumberOfTestImages = sizeTestLabels - UInt(MNISTLabelsMetadataPrefixSize)

    }
    
    func getRandomTrainingBatch(device: MTLDevice, batchSize: UInt, labels: inout MPSNDArray?) -> MPSNDArray {
        let xInputDesc = MPSNDArrayDescriptor(dataType: .float32, shape: [batchSize as NSNumber, MNISTSize * MNISTSize as NSNumber])
        let xInput = MPSNDArray(device: device, descriptor: xInputDesc)
        
        let xLabelsDesc = MPSNDArrayDescriptor(dataType: .float32, shape: [batchSize as NSNumber, MNISTNumClasses as NSNumber])
        let xLabel = MPSNDArray(device: device, descriptor: xLabelsDesc)
        
        var inputVals = [Float](repeating: 0, count: Int(batchSize) * MNISTSize * MNISTSize)
        var labelVals = [Float](repeating: 0, count: Int(batchSize) * MNISTNumClasses)

        for batchInd in 0..<Int(batchSize) {
            let randomNormVal = Float.random(in: 0...1)
            let randomImageIdx = Int(randomNormVal * Float(totalNumberOfTrainImages))
            seed += 1

            let valueOffset = MNISTImageMetadataPrefixSize + randomImageIdx * MNISTSize * MNISTSize
            for ind in 0..<(MNISTSize * MNISTSize) {
                inputVals[batchInd * MNISTSize * MNISTSize + ind] = Float(dataTrainImage![valueOffset + ind]) / Float(255)
            }
            
            let labelOffset = MNISTLabelsMetadataPrefixSize + randomImageIdx
            for classIdx in 0..<MNISTNumClasses {
                if classIdx == dataTrainLabel![labelOffset] {
                    labelVals[batchInd * MNISTNumClasses + classIdx] = 1
                } else {
                    labelVals[batchInd * MNISTNumClasses + classIdx] = 0
                }
            }
        }
        
        xInput.writeBytes(&inputVals, strideBytes: nil)
        xLabel.writeBytes(&labelVals, strideBytes: nil)
        
        labels = xLabel
        
        return xInput
    }
    
    func getTrainingBatchWithDevice(device: MTLDevice, batchIndex: Int, batchSize: Int, labels: inout MPSNDArray?) -> MPSNDArray {
        let xInputDesc = MPSNDArrayDescriptor(dataType: .float32, shape: [batchSize as NSNumber, MNISTSize * MNISTSize as NSNumber])
        let xInput = MPSNDArray(device: device, descriptor: xInputDesc)
        
        let xLabelsDesc = MPSNDArrayDescriptor(dataType: .float32, shape: [batchSize as NSNumber, MNISTNumClasses as NSNumber])
        let xLabel = MPSNDArray(device: device, descriptor: xLabelsDesc)
        
        var inputVals = [Float](repeating: 0, count: Int(batchSize) * MNISTSize * MNISTSize)
        var labelVals = [Float](repeating: 0, count: Int(batchSize) * MNISTNumClasses)
        
        for batchInd in 0..<Int(batchSize) {
            let imageIdx = batchIndex * batchSize + batchInd

            let valueOffset = MNISTImageMetadataPrefixSize + imageIdx * MNISTSize * MNISTSize
            for ind in 0..<(MNISTSize * MNISTSize) {
                inputVals[batchInd * MNISTSize * MNISTSize + ind] = Float(dataTrainImage![valueOffset + ind]) / Float(255)
            }
            
            let labelOffset = MNISTLabelsMetadataPrefixSize + imageIdx
            for classIdx in 0..<MNISTNumClasses {
                if classIdx == dataTrainLabel![labelOffset] {
                    labelVals[batchInd * MNISTNumClasses + classIdx] = 1
                } else {
                    labelVals[batchInd * MNISTNumClasses + classIdx] = 0
                }
            }
        }
        
        xInput.writeBytes(&inputVals, strideBytes: nil)
        xLabel.writeBytes(&labelVals, strideBytes: nil)
        
        labels = xLabel
        
        return xInput
    }
}

