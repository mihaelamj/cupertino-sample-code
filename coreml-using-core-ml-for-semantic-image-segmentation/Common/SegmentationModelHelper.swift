/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The functions that extend Core ML for segmentation model inference.
*/

import CoreML

extension MLModel {
    /// The segmentation labels specified in the metadata.
    var segmentationLabels: [String] {
        if let metadata = modelDescription.metadata[.creatorDefinedKey] as? [String: Any],
           let params = metadata["com.apple.coreml.model.preview.params"] as? String,
           let data = params.data(using: .utf8),
           let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let labels = parsed["labels"] as? [String] {
            return labels
        } else {
            return []
        }
    }
}

extension MLShapedArray where Scalar: Hashable & Comparable {
    /// Returns a sorted list of all values in the shaped array, and removes duplicates.
    var uniqueValues: [Scalar] {
        Set(scalars).sorted()
    }
}
