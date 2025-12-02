/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A subclass of UIView that represents the composition, video composition, and
 audio mix objects in a diagram.
*/

import Foundation
import UIKit
import AVFoundation

enum TimeSliderInset: Int {
    case leftInset = 50
    case rightInset = 60
    case leftMarginInset = 4
}

enum Banner: Int {
    case height = 20
    case idealRowHeight = 36
    case gapAfterRows = 4
}

/// The composition track segment information to display on the screen in the debug view.
struct CompositionTrackSegmentInfo {
    var timeRange = CMTimeRange.zero
    var empty = true
    var mediaType = AVMediaType.video
    var description = String("")
}

/// The video composition information to display on the screen in the debug view.
struct VideoCompositionStageInfo {
    var timeRange = CMTimeRange.zero
    var layerNames = [String]()
    var opacityRamps = [String: [NSValue]]()

}

/// Draw a string vertically centered in the specified rectangle using the provided attributes.
extension String {
    func drawVerticallyCentered(in rect: CGRect) {
        /*
         Create a paragraph style attribute with the subattributes for foreground
         color and paragraph style set.
        */
        let style = NSMutableParagraphStyle()
        style.setParagraphStyle(NSMutableParagraphStyle.default)
        style.alignment = .center
        let attributes = [NSAttributedString.Key.foregroundColor: UIColor.white,
                        NSAttributedString.Key.paragraphStyle: style]
        let size = self.size(withAttributes: attributes)
        
        var newCenteredRect = rect
        newCenteredRect.origin.y += (newCenteredRect.size.height - size.height) / 2.0
        // Draw the text centered in the specified rectangle.
        self.draw(in: newCenteredRect, withAttributes: attributes)
    }
}

class CompositionDebugView: UIView {
        
    private var drawingLayer: CALayer = CALayer()
    private var duration = CMTimeMake(value: 1, timescale: 1)

    private var compositionTrackSegmentInfo = [[CompositionTrackSegmentInfo]]()
    private var volumeRampAsPoints = [[CGPoint]]()
    private var videoCompositionStages = [VideoCompositionStageInfo]()
    
    private var scaledDurationToWidth: CGFloat = 0
    
    private var context: CGContext!
    
    private let avcompositionString = String("AVComposition")
    private let emptyString = String("Empty")
    private let avvideocompositionString = String("AVVideoComposition")
    private let avaudiomixString = String("AVAudioMix")

    private var bannerRect: CGRect = CGRect()
    private var runningTop: CGFloat = 0.0
    private var rowRect: CGRect = CGRect()
    
    private var playerItem: AVPlayerItem!
    
    // MARK: - View
    override func willMove(toSuperview newSuperview: UIView?) {
        drawingLayer.frame = self.bounds
        drawingLayer.delegate = self
        drawingLayer.setNeedsDisplay()
    }

    // MARK: - Synchronization
    /**
     Uses the passed-in player item parameter to synchronize with its own drawing. It builds its visual
     display from the composition, video composition, and audio mix associated with the player item.
     */
    func synchronize(with playerItem: AVPlayerItem) {
        self.playerItem = playerItem
        
        if let composition = playerItem.asset as? AVMutableComposition {
            compositionTrackSegmentInfo = trackSegmentInfo(from: composition.tracks)
            duration = CMTimeMaximum(duration, composition.duration)
        }

        if let audioMix = playerItem.audioMix {
            volumeRampAsPoints = volumeRampPoints(from: audioMix, duration: duration)
        }

        if let videoComposition = playerItem.videoComposition {
            videoCompositionStages = videoCompStageInfo(from: videoComposition.instructions)
        }

        drawingLayer.setNeedsDisplay()
        self.setNeedsDisplay()
    }

    // MARK: - Composition Drawing
    /// Draws the category name to the graphics context.
    private func draw(categoryName name: String) {
        bannerRect.origin.y = runningTop
        context.setFillColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.00)
        (name as NSString).draw(in: bannerRect, withAttributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        runningTop += bannerRect.size.height
    }

    /// Draws the track segment information to the graphics context in the specified destination rectangle.
    private func draw(_ trackSegmentInfos: [CompositionTrackSegmentInfo], in destRect: CGRect) {
        var segmentRect = destRect
        for trackSegmentInfo in trackSegmentInfos {
            segmentRect.size.width = CGFloat(CMTimeGetSeconds(trackSegmentInfo.timeRange.duration)) *
                    scaledDurationToWidth
            
            if trackSegmentInfo.empty {
                context.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
                emptyString.drawVerticallyCentered(in: segmentRect)

            } else {
                if trackSegmentInfo.mediaType == AVMediaType.video {
                    context.setFillColor(red: 0.0, green: 0.36, blue: 0.36, alpha: 1.0)
                    context.setStrokeColor(red: 0.0, green: 0.50, blue: 0.50, alpha: 1.0)
                } else {
                    context.setFillColor(red: 0.0, green: 0.24, blue: 0.36, alpha: 1.0)
                    context.setStrokeColor(red: 0.0, green: 0.33, blue: 0.60, alpha: 1.0)
                }
                context.setLineWidth(2.0)
                context.addRect(segmentRect.insetBy(dx: 3.0, dy: 3.0))
                context.drawPath(using: CGPathDrawingMode.fillStroke)
                context.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
                trackSegmentInfo.description.drawVerticallyCentered(in: segmentRect)

            }
            segmentRect.origin.x += segmentRect.size.width
        }
    }

    /// Draw all the composition tracks.
    private func drawCompositionTracks() {
        if !compositionTrackSegmentInfo.isEmpty {
            draw(categoryName: avcompositionString)
            
            for trackSegmentInfos in compositionTrackSegmentInfo {
                rowRect.origin.y = runningTop
                draw(trackSegmentInfos, in: rowRect)
                runningTop += rowRect.size.height
            }
            runningTop += CGFloat(Banner.gapAfterRows.rawValue)
        }
    }

    /// Draw the opacity ramps for the video composition in the debug view.
    private func draw(ramps rampArray: [NSValue], in layerRect: CGRect) {
        var rampRect = layerRect
        rampRect.size.width = CGFloat(CMTimeGetSeconds(duration)) * scaledDurationToWidth
        rampRect = rampRect.insetBy(dx: 3.0, dy: 3.0)
        
        context.beginPath()
        context.setStrokeColor(red: 0.95, green: 0.68, blue: 0.09, alpha: 1.0)
        context.setLineWidth(2.0)
        
        var firstPoint = true
        for pointValue in rampArray {
            let timeVolumePoint = pointValue.cgPointValue
            var pointInRow = CGPoint(x: 0.0, y: 0.0)
            pointInRow.x = CGFloat(seconds(from: CMTimeMakeWithSeconds(Float64(timeVolumePoint.x),
                    preferredTimescale: 1), scaledDurationToWidth: scaledDurationToWidth) - 3.0)
            pointInRow.y = rampRect.origin.y + ( 0.9 - 0.8 * timeVolumePoint.y ) * rampRect.size.height
            
            pointInRow.x = max(pointInRow.x, rampRect.minX)
            pointInRow.y = min(pointInRow.y, rampRect.maxX)
             
            if firstPoint {
                context.move(to: CGPoint(x: pointInRow.x, y: pointInRow.y))
                firstPoint = false
            } else {
                context.addLine(to: CGPoint(x: pointInRow.x, y: pointInRow.y))
            }
        }
        context.strokePath()
    }
    
    /// Draw the video composition information into the specified rectangle in the graphics context.
    private func draw(stageInfo stage: VideoCompositionStageInfo, in stageRect: CGRect) {
        let layerCount = stage.layerNames.count
        var layerRect = stageRect
        if layerCount > 0 {
            layerRect.size.height /= CGFloat(layerCount)
        }
        
        for layerName in stage.layerNames {
            if layerName.hash % 2 == 1 {
                context.setFillColor(red: 0.55, green: 0.02, blue: 0.02, alpha: 1.0)
                context.setStrokeColor(red: 0.87, green: 0.10, blue: 0.10, alpha: 1.0)
            } else {
                context.setFillColor(red: 0.0, green: 0.40, blue: 0.76, alpha: 1.0)
                context.setStrokeColor(red: 0.0, green: 0.67, blue: 1.0, alpha: 1.0)
            }
            context.setLineWidth(2.0)
            context.addRect(layerRect.insetBy(dx: 3.0, dy: 1.0))
            context.drawPath(using: CGPathDrawingMode.fillStroke)
            
            // If there are two layers, use a gradient fill for the first.
            context.setFillColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            layerName.drawVerticallyCentered(in: layerRect)

            let opacityRampArray = stage.opacityRamps[layerName as String]
            guard let rampArray = opacityRampArray else { continue }
            if !rampArray.isEmpty {
                draw(ramps: rampArray, in: layerRect)
            }
            layerRect.origin.y += layerRect.size.height
        }
    }
    
    /// Draw the video composition.
    private func drawVideoComposition() {
        if !videoCompositionStages.isEmpty {
            draw(categoryName: avvideocompositionString)

            rowRect.origin.y = runningTop
            var stageRect = rowRect
            for stage in videoCompositionStages {
                stageRect.size.width = CGFloat(CMTimeGetSeconds(stage.timeRange.duration)) *
                                                    scaledDurationToWidth
                draw(stageInfo: stage, in: stageRect)
                stageRect.origin.x += stageRect.size.width
            }
            runningTop += rowRect.size.height
            runningTop += CGFloat(Banner.gapAfterRows.rawValue)
        }
    }
    
    /// Draw the volume ramp in the specified rectangle in the graphics context.
    private func draw(volumeRampPoints: [CGPoint], in destRect: CGRect) {
        var rampRect = destRect
        rampRect.size.width = CGFloat(CMTimeGetSeconds(duration)) * scaledDurationToWidth
        rampRect = rampRect.insetBy(dx: 3.0, dy: 3.0)
        
        // Darker red.
        context.setFillColor(red: 0.55, green: 0.02, blue: 0.02, alpha: 1.00)
        context.setStrokeColor(red: 0.87, green: 0.10, blue: 0.10, alpha: 1.0)
        context.setLineWidth(2.0)
        context.addRect(rampRect)
        context.drawPath(using: CGPathDrawingMode.fillStroke)
        
        context.beginPath()
        context.setFillColor(red: 0.95, green: 0.68, blue: 0.09, alpha: 1.0)
        context.setLineWidth(3.0)
        var firstPoint = true
        
        for volumeRampPoint in volumeRampPoints {
            let timeVolumePoint = volumeRampPoint
            var pointInRow = CGPoint(x: 0, y: 0)
            
            pointInRow.x = rampRect.origin.x + timeVolumePoint.x * scaledDurationToWidth
            pointInRow.y = rampRect.origin.y + ( 0.9 - 0.8 * timeVolumePoint.y ) * rampRect.size.height
            
            pointInRow.x = max(pointInRow.x, rampRect.minX)
            pointInRow.y = min(pointInRow.y, rampRect.maxX)
            
            if firstPoint {
                context.move(to: CGPoint(x: pointInRow.x, y: pointInRow.y))
                firstPoint = false
            } else {
                context.addLine(to: CGPoint(x: pointInRow.x, y: pointInRow.y))
            }
        }
        context.strokePath()
    }
    
    /// Draw the audio mix.
    private func drawAudioMix() {
        if !volumeRampAsPoints.isEmpty {
            draw(categoryName: avaudiomixString)

            for volumeRampPoint in volumeRampAsPoints {
                rowRect.origin.y = runningTop
                draw(volumeRampPoints: volumeRampPoint, in: rowRect)
                runningTop += rowRect.size.height
            }
            runningTop += CGFloat(Banner.gapAfterRows.rawValue)
        }
    }

    // MARK: - UIView Drawing
    
    /**
     Draws the composition, video composition, and audio mix within the passed-in rectangle.
     
     Note: This is a UIView draw function override. Subclasses that use technologies like Core Graphics
     and UIKit to draw their view’s content override this method and implement their drawing code here.
    */
    override func draw(_ rect: CGRect) {
        guard let currentContext = UIGraphicsGetCurrentContext() else { return }
        context = currentContext
        
        let rect = rect.insetBy(dx: CGFloat(TimeSliderInset.leftMarginInset.rawValue), dy: 4.0)

        let numRows = compositionTrackSegmentInfo.count + volumeRampAsPoints.count + videoCompositionStages.count
        // Returns 1 if the banner array isn't empty; otherwise, returns 0.
        let banners: (Int) -> Int = { (arrayCount) in
            return (arrayCount > 0) ? 1 : 0
        }
        let numBanners = banners(compositionTrackSegmentInfo.count) + banners(volumeRampAsPoints.count) +
                            banners(videoCompositionStages.count)
        let rowHeight = rowHeight(from: rect.size.height, bannerCount: numBanners, rowCount: numRows)

        runningTop = rect.origin.y
        
        bannerRect = rect
        bannerRect.size.height = CGFloat(Banner.height.rawValue)
        bannerRect.origin.y = runningTop
        
        rowRect = rect
        rowRect.size.height = CGFloat(rowHeight)
        rowRect.origin.x += CGFloat(TimeSliderInset.leftInset.rawValue)
        rowRect.size.width -= (CGFloat(TimeSliderInset.leftInset.rawValue) +
                                CGFloat(TimeSliderInset.rightInset.rawValue))
        scaledDurationToWidth = rowRect.size.width / CGFloat(CMTimeGetSeconds(duration))

        drawCompositionTracks()
        drawVideoComposition()
        drawAudioMix()
        
        if !compositionTrackSegmentInfo.isEmpty {
            /*
             Add the red band layer, along with the scrubbing animation, to a
             AVSynchronizedLayer for precise timing information.
            */
            makeScrubbingAnimation()
        }
    }
    
    // MARK: - Utilities
    
    /**
      Creates a Core Animation layer that derives its timing from a player item to synchronize layer animations
     with media playback. The layer draws a red-and-white timeline marker band.
    */
    private func makeScrubbingAnimation() {
        let syncLayer = AVSynchronizedLayer(playerItem: playerItem)
        self.layer.sublayers = nil
        syncLayer.addSublayer(timeMarkerRedBand(layerBounds: self.layer.bounds,
            viewHeight: self.bounds.size.height, theX: rowRect.origin.x,
            duration: duration, scaledDurationToWidth: scaledDurationToWidth))
        self.layer.addSublayer(syncLayer)
    }
}
