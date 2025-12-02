/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Core Animation-related utility functions that the composition debug view uses.
*/

import Foundation
import UIKit
import AVFoundation

/*
 Creates a red-and-white timeline marker band using the provided parameters.
 The app draws this timeline marker band in the debug view in sync with the
 composition playback in the player view.
*/
func timeMarkerRedBand(layerBounds: CGRect, viewHeight: CGFloat, theX: CGFloat,
                       duration: CMTime, scaledDurationToWidth: CGFloat) -> CAShapeLayer {
    let visibleRect = layerBounds
    var currentTimeRect = visibleRect
    
    currentTimeRect.origin.x = 0
    // Set the red band of the time marker to 8 pixels wide.
    currentTimeRect.size.width = 8
    let timeMarkerRedBandLayer = timeMarkerBand(with: currentTimeRect,
            point: CGPoint(x: theX, y: viewHeight / 2), color:
                CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5))

    currentTimeRect.origin.x = 0
    currentTimeRect.size.width = 1
    
    /*
     Position the white line layer of the time marker at the center of the red
     band layer.
    */
    let timeMarkerWhiteLineLayer = timeMarkerBand(with: currentTimeRect,
            point: CGPoint(x: 4, y: viewHeight / 2), color:
                CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0))
    /*
     Add the white line layer to the red band layer. This animates
     the red band layer, which in turn animates its sublayers.
    */
    timeMarkerRedBandLayer.addSublayer(timeMarkerWhiteLineLayer)
    
    /*
     The scrubbing animation controls the x position of the time marker.
     On the left side, it's bound to where the first segment rectangle of the
     composition starts. On the right side, it's bound to where the last
     segment rectangle of the composition ends.
     Playback at rate 1.0 requires the timeMarker "duration" time to reach one
     end to the other. This is marked as the duration of the animation.
    */
    timeMarkerRedBandLayer.add(scrubbingAnimation(for: duration,
                    scaledDurationToWidth: scaledDurationToWidth), forKey: nil)
    
    return timeMarkerRedBandLayer
}

/*
 Creates a CABasicAnimation object to provide single-keyframe animation capabilities
 for the layer's 'position' property. The system uses this to animate the timeline slider.
*/
private func scrubbingAnimation(for duration: CMTime, scaledDurationToWidth: CGFloat)
                                    -> CABasicAnimation {
    let scrubbingAnimation = CABasicAnimation(keyPath: "position.x")
    scrubbingAnimation.fromValue = NSNumber(value: seconds(from: CMTime.zero,
                                scaledDurationToWidth: scaledDurationToWidth))
    scrubbingAnimation.toValue = NSNumber(value: seconds(from: duration,
                                scaledDurationToWidth: scaledDurationToWidth))
    scrubbingAnimation.isRemovedOnCompletion = false
    scrubbingAnimation.beginTime = AVCoreAnimationBeginTimeAtZero
    scrubbingAnimation.duration = CMTimeGetSeconds(duration)
    scrubbingAnimation.fillMode = CAMediaTimingFillMode.both
    
    return scrubbingAnimation
}

/// Creates a timeline marker band with the provided rectangle, color, and position.
private func timeMarkerBand(with frame: CGRect, point: CGPoint, color: CGColor) -> CAShapeLayer {
    let timeMarkerLineLayer = CAShapeLayer()
    timeMarkerLineLayer.frame = frame
    timeMarkerLineLayer.position = point
    let linePath = CGPath(rect: frame, transform: nil)
    timeMarkerLineLayer.fillColor = color
    timeMarkerLineLayer.path = linePath
    
    return timeMarkerLineLayer
}

/*
 A utility that scales a CMTime by a duration value and converts the scaled value to
 seconds.
*/
func seconds(from time: CMTime, scaledDurationToWidth: CGFloat) -> Double {
    var seconds: Double = 0
    if CMTIME_IS_NUMERIC(time) && CMTimeCompare(time, CMTime.zero) == 1 {
        seconds = CMTimeGetSeconds(time)
    }
    
    return seconds * Double(scaledDurationToWidth) +
        Double(TimeSliderInset.leftInset.rawValue) +
        Double(TimeSliderInset.leftMarginInset.rawValue)
}
