/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The file compressor class.
*/

import Foundation
import Compression


class Compressor: ObservableObject {
    
    let useSwiftAPI = true
    
    var message: String = ""
    
    @Published var progress: Double = 0
    @Published var totalUnitCount: Double = 0
    
    let encodeAlgorithm = Algorithm.lzfse
    
    public func compress(urls: [URL]) -> Bool {
        
        for url in urls {
            // If the dragging item's path extension relates to a known
            // compression algorithm, use that algorithm to decode it.
            // Otherwise, compress that item using `encodeAlgorithm`.
            let algorithm: Algorithm
            let operation: FilterOperation
                                        
            if let decodeAlgorithm = Algorithm(name: url.pathExtension) {
                algorithm = decodeAlgorithm
                operation = .decompress
                message = "Decompressing \(url.lastPathComponent)"
            } else {
                algorithm = self.encodeAlgorithm
                operation = .compress
                message = "Compressing \(url.lastPathComponent)"
            }
                                        
            if
                let sourceFileHandle = try? FileHandle(forReadingFrom: url),
                let sourceLength = FileHelper.fileSize(atURL: url),
                let fileName = url.pathComponents.last,
                let fileNameDeletingPathExtension = url.deletingPathExtension().pathComponents.last,
                let destinationFileHandle = FileHandle.makeFileHandle(forWritingToFileNameInTempDirectory:
                    operation == .compress
                        ? fileName + self.encodeAlgorithm.pathExtension
                        : fileNameDeletingPathExtension) {
                self.totalUnitCount = Double(sourceLength)
                
                Task {
                    if useSwiftAPI {
                        Compressor.streamingCompression(operation: operation,
                                                        sourceFileHandle: sourceFileHandle,
                                                        destinationFileHandle: destinationFileHandle,
                                                        algorithm: algorithm) { progress in
                            DispatchQueue.main.async {
                                self.progress = Double(progress)
                            }
                        }
                    } else {
                        Compressor.streamingCompression(operation: operation.rawValue,
                                                        sourceFileHandle: sourceFileHandle,
                                                        destinationFileHandle: destinationFileHandle,
                                                        algorithm: algorithm.rawValue) { progress in
                            
                            DispatchQueue.main.async {
                                self.progress = Double(progress)
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.progress = 0
                        self.totalUnitCount = 0
                        self.message = "Operation complete.\nResult written to: \(NSTemporaryDirectory())"
                    }
                }
            } else {
                message = "⚠️ Unable to complete operation."
            }
        }
        return true
    }
    
    static let bufferSize = 32_768

    /// Encodes or decodes the file that's associated with `sourceFileHandle` and writes the result
    /// to the file that's associated with `destinationFileHandle`.
    ///
    /// This version of `streamingCompression` uses the Compression Swift API.
    static func streamingCompression(operation: FilterOperation,
                                     sourceFileHandle: FileHandle,
                                     destinationFileHandle: FileHandle,
                                     algorithm: Algorithm,
                                     progressUpdateFunction: (UInt64) -> Void) {
        
        do {
            let outputFilter = try OutputFilter(operation,
                                                using: algorithm) {
                (data: Data?) -> Void in
                if let data = data {
                    destinationFileHandle.write(data)
                }
            }
            
            while true {
                let subdata = sourceFileHandle.readData(ofLength: bufferSize)
                
                progressUpdateFunction(sourceFileHandle.offsetInFile)
                
                try outputFilter.write(subdata)
                if subdata.count < bufferSize {
                    break
                }
            }
        } catch {
            fatalError("Error occurred during encoding: \(error.localizedDescription).")
        }

        sourceFileHandle.closeFile()
        destinationFileHandle.closeFile()
    }

    /// Encodes or decodes the file that's associated with `sourceFileHandle` and writes the result
    /// to the file that's associated with `destinationFileHandle`.
    ///
    /// This version of `streamingCompression` uses the Compression C API.
    static func streamingCompression(operation: compression_stream_operation,
                                     sourceFileHandle: FileHandle,
                                     destinationFileHandle: FileHandle,
                                     algorithm: compression_algorithm,
                                     progressUpdateFunction: (UInt64) -> Void) {
        
        let destinationBufferPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            destinationBufferPointer.deallocate()
        }
        
        // Create the compression_stream and throw an error if failed.
        let streamPointer = UnsafeMutablePointer<compression_stream>.allocate(capacity: 1)
        var status = compression_stream_init(streamPointer, operation, algorithm)
        guard status != COMPRESSION_STATUS_ERROR else {
            fatalError("Unable to initialize the compression stream.")
        }
        defer {
            compression_stream_destroy(streamPointer)
            streamPointer.deallocate()
        }
        
        // Set up the stream after initialization.
        streamPointer.pointee.src_size = 0
        streamPointer.pointee.dst_ptr = destinationBufferPointer
        streamPointer.pointee.dst_size = bufferSize
        
        var sourceData: Data?
        repeat {
            var flags = Int32(0)
            
            // If this iteration has consumed all of the source data,
            // read a new buffer from the input file.
            if streamPointer.pointee.src_size == 0 {
                sourceData = sourceFileHandle.readData(ofLength: bufferSize)
                
                streamPointer.pointee.src_size = sourceData!.count
                if sourceData!.count < bufferSize {
                    flags = Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
                }
            }
            
            // Perform compression or decompression.
            if let sourceData = sourceData {
                let count = sourceData.count
                
                sourceData.withUnsafeBytes {
                    let baseAddress = $0.bindMemory(to: UInt8.self).baseAddress!
                    
                    streamPointer.pointee.src_ptr = baseAddress.advanced(by: count - streamPointer.pointee.src_size)
                    status = compression_stream_process(streamPointer, flags)
                }
            }
            
            switch status {
                case COMPRESSION_STATUS_OK, COMPRESSION_STATUS_END:
                    
                    // Get the number of bytes put in the destination buffer.
                    // This is the difference between `stream.dst_size` before the
                    // call (`bufferSize`), and `stream.dst_size` after the call.
                    let count = bufferSize - streamPointer.pointee.dst_size
                    
                    let outputData = Data(bytesNoCopy: destinationBufferPointer,
                                          count: count,
                                          deallocator: .none)
                    
                    // Write all produced bytes to the output file.
                    destinationFileHandle.write(outputData)
                    
                    // Reset the stream to receive the next batch of output.
                    streamPointer.pointee.dst_ptr = destinationBufferPointer
                    streamPointer.pointee.dst_size = bufferSize
                    progressUpdateFunction(sourceFileHandle.offsetInFile)
                case COMPRESSION_STATUS_ERROR:
                    print("COMPRESSION_STATUS_ERROR.")
                    return
                    
                default:
                    break
            }
            
        } while status == COMPRESSION_STATUS_OK
        
        sourceFileHandle.closeFile()
        destinationFileHandle.closeFile()
    }
}

extension Algorithm {
    var name: String {
        switch self {
            case .lz4:
                return "lz4"
            case .zlib:
                return "zlib"
            case .lzma:
                return "lzma"
            case .lzfse:
                return "lzfse"
            default:
                fatalError("Unknown compression algorithm.")
        }
    }
    
    var pathExtension: String {
        return "." + name
    }
}

extension Algorithm {
    init?(name: String) {
        switch name.lowercased() {
            case "lz4":
                self = .lz4
            case "zlib":
                self = .zlib
            case "lzma":
                self = .lzma
            case "lzfse":
                self = .lzfse
            default:
                return nil
        }
    }
}
