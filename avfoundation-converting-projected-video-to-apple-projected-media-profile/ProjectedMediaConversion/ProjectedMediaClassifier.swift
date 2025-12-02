/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Classifies whether a video file conforms to Apple Projected Media Profile
 or is of a compatible alternative format that can be interpreted as such.
*/

import AVFoundation
import CoreMedia

final class ProjectedMediaClassifier {
	
	let convertedFromSpherical: Bool
	let isProjectedMediaProfile: Bool
	let isFramePacked: Bool
	let isHEVC: Bool
	
	let projectionKind: String?
	let viewPackingKind: String?

	init(from url: URL) async throws {
		let assetOptions = [AVURLAssetShouldParseExternalSphericalTagsKey: true] as [String: Any]
		let asset = AVURLAsset(url: url, options: assetOptions)
		
		// simplification for sample - only looks at first matching video track
		guard let videoTrack = try await asset.loadTracks(withMediaCharacteristic: .visual).first else {
			convertedFromSpherical = false
			isProjectedMediaProfile = false
			isFramePacked = false
			isHEVC = false
			projectionKind = nil
			viewPackingKind = nil
			return
		}
		
		// simplification for sample - only looks at first format description
		guard let formatDescription = try await videoTrack.load(.formatDescriptions).first else {
			fatalError("Failed to retrieve format description from video track")
		}

		if let extProjectionKind = formatDescription.extensions[.projectionKind] {
			switch extProjectionKind {
			case .projectionKind(.equirectangular):
				projectionKind = "Equirectangular"
				isProjectedMediaProfile = true
			case .projectionKind(.halfEquirectangular):
				projectionKind = "HalfEquirectangular"
				isProjectedMediaProfile = true
			case .projectionKind(.parametricImmersive):
				projectionKind = "ParametricImmersive"
				isProjectedMediaProfile = true
			default:
				projectionKind = nil
				isProjectedMediaProfile = false
			}
		} else {
			projectionKind = nil
			isProjectedMediaProfile = false
		}
		
		if formatDescription.extensions[.convertedFromExternalSphericalTags] != nil {
			convertedFromSpherical = true
		} else {
			convertedFromSpherical = false
		}
		
		if let extViewPackingKind = formatDescription.extensions[.viewPackingKind] {
			switch extViewPackingKind {
			case .viewPackingKind(.sideBySide):
				viewPackingKind = "SideBySide"
				isFramePacked = true
			case .viewPackingKind(.overUnder):
				viewPackingKind = "OverUnder"
				isFramePacked = true
			default:
				viewPackingKind = nil
				isFramePacked = false
			}
		} else {
			viewPackingKind = nil
			isFramePacked = false
		}
		
		let codec = formatDescription.mediaSubType
		isHEVC = (codec == .hevc)
	}
	
	func conformsToAPMPDeliveryVariant() -> Bool {
		// APMP delivery variant is HEVC or MV-HEVC, not frame-packed, and not relying on compatibility with Spherical RFC signaling
		isProjectedMediaProfile && isHEVC && !isFramePacked && !convertedFromSpherical
	}
}

