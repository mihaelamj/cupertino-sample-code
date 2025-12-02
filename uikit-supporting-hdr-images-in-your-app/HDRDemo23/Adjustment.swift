/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure for storing and managing image editing using CIFilters.
*/

import Foundation
import CoreImage
import PhotosUI

struct Adjustment: Identifiable, Codable, Sendable {

    enum Identifier: String, CaseIterable, Codable, Sendable {
        case exposure
        case contrast
        case saturation
        case sepia
    }

    let id: Identifier
    var enabled: Bool = false
    var value: Double = 0.5

    func apply(to image: CIImage?) -> CIImage? {
        guard enabled, let image = image else {
            return image
        }
        return id.apply(to: image, value: value)
    }

    // Set up a default list of adjustments.
    static let defaultAdjustments: [Adjustment] = {
        Adjustment.Identifier.allCases.map { identifier in
            Adjustment(id: identifier, enabled: false, value: identifier.defaultValue)
        }
    }()

}

// Add functionality to support CIFilters and SwiftUI Sliders.
extension Adjustment.Identifier {

    var defaultValue: Double {
        switch self {
        case .exposure:
            return 0.0
        case .contrast:
            return 1.0
        case .saturation:
            return 1.0
        case .sepia:
            return 1.0
        }
    }

    var range: ClosedRange<Double> {
        switch self {
        case .exposure:
            return -2.0...2.0
        case .contrast:
            return 0.5...1.5
        case .saturation:
            return 0.0...2.0
        case .sepia:
            return 0.0...1.0
        }
    }

    func apply(to image: CIImage, value: Double) -> CIImage {
        switch self {
        case .exposure:
            return image.applyingFilter("CIExposureAdjust", parameters: ["inputEV": value])
        case .contrast:
            return image.applyingFilter("CIColorControls", parameters: ["inputContrast": value])
        case .saturation:
            return image.applyingFilter("CIColorControls", parameters: ["inputSaturation": value])
        case .sepia:
            return image.applyingFilter("CISepiaTone", parameters: ["inputIntensity": value])
        }
    }

}

// Add functionality to support Photos edits.
extension Adjustment {

    static let formatIdentifier = "\(Bundle.main.bundleIdentifier!).edits"
    static let formatVersion = "1.0"

    static func canLoad(from adjustmentData: PHAdjustmentData) -> Bool {
        return adjustmentData.formatIdentifier == formatIdentifier && adjustmentData.formatVersion == formatVersion
    }

    static func load(from adjustmentData: PHAdjustmentData) -> [Adjustment]? {
        guard canLoad(from: adjustmentData) else {
            return nil
        }
        return try? JSONDecoder().decode(Array<Adjustment>.self, from: adjustmentData.data)
    }

    static func save(_ adjustments: [Adjustment]) -> PHAdjustmentData? {
        guard let data = try? JSONEncoder().encode(adjustments) else {
            return nil
        }
        return PHAdjustmentData(formatIdentifier: formatIdentifier, formatVersion: formatVersion, data: data)
    }

}
