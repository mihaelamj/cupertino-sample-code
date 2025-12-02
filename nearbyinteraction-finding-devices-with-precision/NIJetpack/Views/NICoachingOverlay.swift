/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Views and utilities for the ARView coaching overlay that NISession uses to help direct a person using the app.
*/

import SwiftUI
import NearbyInteraction
import os
import Combine

// Extensions for `FindingMode` that display messages and guidance used on `NICoachingOverlay`.
extension FindingMode {
    func moveMessage() -> String {
        switch self {
        case .exhibit: "Move your phone up and down to see exhibit location."
        case .visitor: "Move your phone up and down to find other visitors."
        }
    }

    func guidanceWhenNoDistance() -> String {
        switch self {
        case .exhibit: "Finding next exhibit…"
        case .visitor: "Finding other visitors…"
        }
    }
    
    func guidanceWhenNoAngle() -> String {
        switch self {
        case .exhibit: "Move side to side."
        case .visitor: "Move to another location."
        }
    }
    
    func guidanceWhenInGoodMeasurement() -> String {
        switch self {
        case .exhibit: "Go to the Exhibit."
        case .visitor: "Meet another visitor."
        }
    }
    
    func generateGuidance(with nearbyObject: NINearbyObject?) -> String {
        guard let object = nearbyObject, object.distance != nil else {
            return guidanceWhenNoDistance()
        }
        guard object.horizontalAngle != nil else {
            return guidanceWhenNoAngle()
        }
        return guidanceWhenInGoodMeasurement()
    }
}

// An overlay view for coaching or directing the person using the app.
struct NICoachingOverlay: View {
    let findingMode: FindingMode

    // Variables observed from `NISessionManager` to update view.
    var isConverged: Bool = false
    var measurementQuality: MeasurementQualityEstimator.MeasurementQuality?
    var lastNearbyObject: NINearbyObject?
    var showCoachingOverlay: Bool = true
    var showUpdownText: Bool = false
    
    // State variable for image animation.
    @State var animateSymbol = false

    var body: some View {
        VStack {
            // Scale the image based on distance, if available.
            let rate: Float = showCoachingOverlay ? 1 : 0.3
            let distance = lastNearbyObject?.distance ?? 0.5
            let distanceScale = distance.scale(minRange: 0.15, maxRange: 1.0, minDomain: 0.5, maxDomain: 2.0)
            let imageScale = ((lastNearbyObject?.horizontalAngle == nil) ? 0.5 : distanceScale) * rate
            
            // Show the distance, if there's any.
            let distString = lastNearbyObject?.distance == nil
            ? ""
            : String(format: "Distance %.2f m", distance)
            
            // Text to display for guiding the person to move their iPhone up and down.
            let upDownText = showUpdownText ? findingMode.moveMessage() : ""
            
            // Display an image to help guide the person using the app.
            let img = Image(systemName: displayImageName())
            if #available(iOS 17, *), findingMode == .visitor, measurementQuality == .unknown {
                img.resizable()
                    .frame(width: 150 * CGFloat(imageScale), height: 150 * CGFloat(imageScale), alignment: .center)
                    // Rotate the image by the horizontal angle, when available.
                    .rotationEffect(imageAngle(orientationRadians: lastNearbyObject?.horizontalAngle))
                    .symbolEffect(.bounce, options: .repeating, value: animateSymbol)
                    .onAppear(perform: {
                        animateSymbol = true
                    })
            } else {
                img.resizable()
                    .frame(width: 200 * CGFloat(imageScale), height: 200 * CGFloat(imageScale), alignment: .center)
                    // Rotate the image by the horizontal angle, when available.
                    .rotationEffect(.init(radians: Double(lastNearbyObject?.horizontalAngle ?? 0.0)))
            }

            // A view that provides guidance with distance text and suggestions on moving the device.
            VStack {
                Text(distString).frame(alignment: .center)
                Text(findingMode.generateGuidance(with: lastNearbyObject)).frame(alignment: .center)
                Text(upDownText).frame(alignment: .center)
            }.opacity(showCoachingOverlay ? 1 : 0)
        }
        .foregroundColor(.white)
        .animation(.smooth, value: showCoachingOverlay)
    }
    
    // The image to use for displaying guidance and direction.
    func displayImageName() -> String {
        if lastNearbyObject?.distance == nil {
            return "sparkle.magnifyingglass"
        }
        
        if lastNearbyObject?.horizontalAngle == nil {
            return "move.3d"
        }
        
        if findingMode == .exhibit {
            return "arrow.up.circle"
        } else {
            if #available(iOS 17, *), measurementQuality == nil || measurementQuality == .unknown {
                return "wave.3.right"
            } else {
                return "arrow.up.circle"
            }
        }
    }

    //  Rotation angle for animated `wave` image.
    func imageAngle(orientationRadians: Float?) -> Angle {
        // The angular correction to make the images point upwards on the screen.
        let imageRotationOffset = Angle(degrees: -90)
        return Angle(radians: Double(orientationRadians ?? 0)) + imageRotationOffset
    }
}
