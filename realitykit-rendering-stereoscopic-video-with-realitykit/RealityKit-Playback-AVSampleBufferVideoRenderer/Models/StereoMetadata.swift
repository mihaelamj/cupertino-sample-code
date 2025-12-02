/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that describes typical stereo metadata.
*/

import CoreVideo
import Foundation

/// A model that describes typical stereo metadata.
struct StereoMetadata {
    /// Describes potential frame-packing approaches.
    enum FramePacking {
        /// Indicates that frames are packed side-by-side.
        case sideBySide

        /// Indicates that frames are packed, one over another.
        case overUnder
    }
    
    /// The current frame packing.
    let framePacking: FramePacking

    // MARK: Internal behavior

    /// Initializes with the specified frame packing applied.
    /// - Parameter framePacking: The prevailing frame packing.
    init(framePacking: FramePacking) {
        self.framePacking = framePacking
    }

    /// Describes horizontal & vertical components of aperture offset.
    typealias ApertureOffset = (horizontal: CGFloat, vertical: CGFloat)
    
    /// Returns the aperture offset for a given buffer size and layer ID.
    /// - Parameters:
    ///   - bufferSize: The input buffer size.
    ///   - layerID: The layer ID corresponding to a given frame.
    /// - Returns: The calculated aperture offset.
    func apertureOffset(for bufferSize: CVImageSize, layerID: Int) -> ApertureOffset {
        if isSideBySide {
            return (
                horizontal: CGFloat(bufferSize.width) * (CGFloat(layerID) - 0.5),
                vertical: 0
            )
        } else {
            return (
                horizontal: 0,
                vertical: CGFloat(bufferSize.height) * (CGFloat(layerID) - 0.5)
            )
        }
    }
    
    /// Returns the horizontal scale for a given frame packing.
    var horizontalScale: CGFloat {
        switch framePacking {
        case .sideBySide:
            return 2
        case .overUnder:
            return 1
        }
    }
    
    /// Returns the vertical scale for a given frame packing.
    var verticalScale: CGFloat {
        switch framePacking {
        case .sideBySide:
            return 1
        case .overUnder:
            return 2
        }
    }

    // MARK: Private behavior

    /// Returns `true` if the frame packing is side-by-side; `false` otherwise.
    private var isSideBySide: Bool {
        return framePacking == .sideBySide
    }
}

// MARK: - StereoMetadata (Default)

extension StereoMetadata {
    /// By default, the stereo metadata assumes side-by-side frame packing.
    static let `default` = StereoMetadata(framePacking: .sideBySide)
}
