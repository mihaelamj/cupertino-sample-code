/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Command line tool that showcases export usage patterns for HEVC videos with alpha.
*/

import AppKit
import Foundation
import AVFoundation
import VideoToolbox
import CoreImage

// Extension to convert status enums to strings for printing.
extension AVAssetExportSession.Status: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown: return "unknown"
        case .waiting: return "waiting"
        case .exporting: return "exporting"
        case .completed: return "completed"
        case .failed: return "failed"
        case .cancelled: return "cancelled"
        @unknown default: return "\(rawValue)"
        }
    }
}

func exportToHEVCWithAlphaAsynchronously(sourceURL: URL,
                                         destinationURL: URL,
                                         handleExportCompletion:
                                           @escaping (_ status: AVAssetExportSession.Status) -> Void) {
    let asset = AVAsset(url: sourceURL)
    AVAssetExportSession.determineCompatibility(ofExportPreset: AVAssetExportPresetHEVCHighestQualityWithAlpha, with: asset, outputFileType: .mov) {
        compatible in if compatible {
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHEVCHighestQualityWithAlpha) else {
                print("Failed to create export session to HEVC with alpha")
                handleExportCompletion(.failed)
                return
            }
            
            // Export
            exportSession.outputURL = destinationURL
            exportSession.outputFileType = .mov
            exportSession.exportAsynchronously {
                handleExportCompletion(exportSession.status)
            }
        } else {
            print("Export Session failed compatibility check")
            handleExportCompletion(.failed)
        }
    }
}

func exportFromHEVCWithAlphaToAVCAsynchronously(sourceURL: URL,
                                                destinationURL: URL,
                                                withPreferredBackgroundColor color: CGColor,
                                                handleExportCompletion:
                                                   @escaping (_ status: AVAssetExportSession.Status) -> Void) {
    let asset = AVAsset(url: sourceURL)
    AVAssetExportSession.determineCompatibility(ofExportPreset: AVAssetExportPresetHighestQuality, with: asset, outputFileType: .mov) {
        compatible in if compatible {
            guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
                print("Failed to create export session to AVC")
                handleExportCompletion(.failed)
                return
            }

            // Setup to use preferred background color
            let prototypeInstruction = AVMutableVideoCompositionInstruction()
            prototypeInstruction.backgroundColor = color
            let videoComposition = AVMutableVideoComposition(propertiesOf: asset, prototypeInstruction: prototypeInstruction )

            // Export
            exportSession.outputURL = destinationURL
            exportSession.outputFileType = .mov
            exportSession.videoComposition = videoComposition
            exportSession.exportAsynchronously {
                handleExportCompletion(exportSession.status)
            }
        } else {
            print("Export Session failed compatibility check")
            handleExportCompletion(.failed)
        }
    }
}

/// Setup Chroma Key Filter
/*
    This filter swaps green pixels with transparency for an acceptable range of
    of brightness values. It can be made more complex with a CIKernel for
    workflows that need additional filtering.
 */
func makeChromaKeyFilter(usingHueFrom minHue: CGFloat,
                         to maxHue: CGFloat,
                         brightnessFrom minBrightness: CGFloat,
                         to maxBrightness: CGFloat) -> CIFilter {
    func getHueAndBrightness(red: CGFloat, green: CGFloat, blue: CGFloat) -> (hue: CGFloat, brightness: CGFloat) {
        let color = NSColor(red: red, green: green, blue: blue, alpha: 1)
        var hue: CGFloat = 0
        var brightness: CGFloat = 0
        color.getHue(&hue, saturation: nil, brightness: &brightness, alpha: nil)
        return (hue: hue, brightness: brightness)
    }
    
    let size = 64
    var cubeRGB = [Float]()
    for zaxis in 0 ..< size {
        let blue = CGFloat(zaxis) / CGFloat(size - 1)
        for yaxis in 0 ..< size {
            let green = CGFloat(yaxis) / CGFloat(size - 1)
            for xaxis in 0 ..< size {
                let red = CGFloat(xaxis) / CGFloat(size - 1)
                
                let (hue, brightness) = getHueAndBrightness(red: red, green: green, blue: blue)
                let alpha: CGFloat = ((minHue <= hue && hue <= maxHue) &&
                    (minBrightness <= brightness && brightness <= maxBrightness)) ? 0: 1
                
                // Pre-multiplied alpha
                cubeRGB.append(Float(red * alpha))
                cubeRGB.append(Float(green * alpha))
                cubeRGB.append(Float(blue * alpha))
                cubeRGB.append(Float(alpha))
            }
        }
    }
    
    let data = cubeRGB.withUnsafeBytes { Data($0) }
    let colorCubeFilter = CIFilter(name: "CIColorCube", parameters: ["inputCubeDimension": size, "inputCubeData": data])
    return colorCubeFilter!
}

func removeGreenChroma (sourceURL: URL, destinationURL: URL, handleExportCompletion: @escaping (_ status: AVAssetExportSession.Status) -> Void ) {
    let asset = AVAsset(url: sourceURL)
    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHEVCHighestQualityWithAlpha) else {
        print("Failed to create export session to HEVC with alpha.")
        handleExportCompletion(.failed)
        return
    }
    
    // Setup video composition with green screen removal filter
    let filter = makeChromaKeyFilter(usingHueFrom: 0.3, to: 0.4, brightnessFrom: 0.05, to: 1.0 )
    let chromaKeyComposition = AVVideoComposition(asset: asset, applyingCIFiltersWithHandler: { request in
        let source = request.sourceImage.clampedToExtent()
        filter.setValue(source, forKey: kCIInputImageKey)
        let output = filter.outputImage!
        // Provide the filter output to the composition
        request.finish(with: output, context: nil)
    })
    
    // Export
    exportSession.outputURL = destinationURL
    exportSession.outputFileType = .mov
    exportSession.videoComposition = chromaKeyComposition
    exportSession.exportAsynchronously {
        handleExportCompletion(exportSession.status)
    }
}

// Export Use-cases
let pendingExports = DispatchGroup()

// 1.From Apple ProRes 4444 to HEVC-with-Alpha

let sourceProRes = URL(fileURLWithPath: "puppets_with_alpha_prores.mov")
let destinationHEVCWithAlpha = URL(fileURLWithPath: "/tmp/puppets_with_alpha_hevc_output.mov")
try? FileManager.default.removeItem(at: destinationHEVCWithAlpha)
pendingExports.enter()
exportToHEVCWithAlphaAsynchronously(sourceURL: sourceProRes, destinationURL: destinationHEVCWithAlpha) { status in
    if status == .completed {
        print("Exported \(sourceProRes) to \(destinationHEVCWithAlpha) successfully")
    } else {
        print("Export from \(sourceProRes) to \(destinationHEVCWithAlpha) failed with status: \(status)")
    }
    pendingExports.leave()
}

// 2. From HEVC-with-alpha to AVC with white background (fallback case)
let sourceHEVCWithAlpha = URL(fileURLWithPath: "puppets_with_alpha_hevc.mov")
let destinationAVCWithWhiteBg = URL(fileURLWithPath: "/tmp/puppets_with_whitebg_avc_output.mov")
try? FileManager.default.removeItem(at: destinationAVCWithWhiteBg)
// Add a white background during fallback to AVC
let white = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
pendingExports.enter()
exportFromHEVCWithAlphaToAVCAsynchronously(
    sourceURL: sourceHEVCWithAlpha,
    destinationURL: destinationAVCWithWhiteBg,
    withPreferredBackgroundColor: white) { status in
    if status == .completed {
        print("Exported \(sourceHEVCWithAlpha) to \(destinationAVCWithWhiteBg) successfully")
    } else {
        print("Export from \(sourceHEVCWithAlpha) to \(destinationAVCWithWhiteBg) failed with status: \(status)")
    }
    pendingExports.leave()
}

// 3. Green Screen Removal
let sourceWithGreenScreen = URL(fileURLWithPath: "puppets_with_greenbg_hevc.mov")
let destinationNoGreenHEVCWithAlpha = URL(fileURLWithPath: "/tmp/puppets_with_nogreen_alpha_hevc_output.mov")
try? FileManager.default.removeItem(at: destinationNoGreenHEVCWithAlpha)
pendingExports.enter()
removeGreenChroma(sourceURL: sourceWithGreenScreen, destinationURL: destinationNoGreenHEVCWithAlpha) { status in
    if status == .completed {
        print("Exported \(sourceWithGreenScreen) to \(destinationNoGreenHEVCWithAlpha) successfully")
    } else {
        print("Export from \(sourceWithGreenScreen) to \(destinationNoGreenHEVCWithAlpha) failed with status: \(status)")
    }
    pendingExports.leave()
}

pendingExports.wait()
print("All Done.")

