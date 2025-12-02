/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides custom shapes to draw bounding boxes and outline facial features.
*/

import SwiftUI
import Vision

/// A custom shape to draw bounding boxes around detected faces.
struct BoundingBox: Shape {
    private let normalizedRect: NormalizedRect
    
    init(observation: any BoundingBoxProviding) {
        normalizedRect = observation.boundingBox
    }
    
    func path(in rect: CGRect) -> Path {
        let rect = normalizedRect.toImageCoordinates(rect.size, origin: .upperLeft)
        return Path(rect)
    }
}

/// A custom shape to draw the observed facial landmarks.
struct FaceLandmark: Shape {
    let region: FaceObservation.Landmarks2D.Region
    
    func path(in rect: CGRect) -> Path {
        let points = region.pointsInImageCoordinates(rect.size, origin: .upperLeft)
        let path = CGMutablePath()
        
        path.move(to: points[0])
        
        for index in 1..<points.count {
            path.addLine(to: points[index])
        }
        
        if region.pointsClassification == .closedPath {
            path.closeSubpath()
        }
        
        return Path(path)
    }
}
