/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension to provide a Graphic Rectangle template.
*/

import ClockKit
import UIKit
import WatchKit

// MARK: - Graphic Rectangle family
//
extension ComplicationController {
    func newGraphicRectangleTemplate(variant: GraphicRectangleVariant, event: Event) -> CLKComplicationTemplate {
        switch variant {
            
        case .largeImage:
            return newGraphicRectangularLargeImage(with: event)
            
        case .standardBody:
            return newGraphicRectangularStandardBody(with: event)
            
        case .textGauge:
            return newGraphicRectangularTextGauge(with: event)
        }
    }
    
    private func newGraphicRectangularLargeImage(with event: Event) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicRectangularLargeImage()
        
        let startDateTime = event.startDateTime(onDate: event.date!)
        let endDateTime = event.endDateTime(onDate: event.date!)
        let image = largeImage(for: event)

        template.imageProvider = CLKFullColorImageProvider(fullColorImage: image)

        let part1 = CLKSimpleTextProvider(text: event.name)
        part1.tintColor = .purple
        let startTimeString = DateFormatter.shortTimeFormatter().string(from: startDateTime)
        let endTimeString = DateFormatter.shortTimeFormatter().string(from: endDateTime)
        let part2 = CLKSimpleTextProvider(text: " \(startTimeString) - \(endTimeString)" )
        part2.tintColor = .orange
        template.textProvider = CLKTextProvider(format: "%@%@", part1, part2)
        
        return template
    }
    
    private func newGraphicRectangularStandardBody(with event: Event) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicRectangularStandardBody()

        let startDateTime = event.startDateTime(onDate: event.date!)
        let endDateTime = event.endDateTime(onDate: event.date!)

        template.headerTextProvider = CLKSimpleTextProvider(text: event.name + " - " + event.desc)
        template.headerTextProvider.tintColor = .purple

        let part1 = CLKSimpleTextProvider(text: "HAS ")
        part1.tintColor = .blue
        let part2 = CLKRelativeDateTextProvider(date: endDateTime, style: .naturalAbbreviated, units: [.minute])
        part2.tintColor = .orange
        let part3 = CLKSimpleTextProvider(text: " TO GO")
        part3.tintColor = .green
        template.body1TextProvider = CLKTextProvider(format: "%@%@%@", part1, part2, part3)
        
        let startTimeString = DateFormatter.shortTimeFormatter().string(from: startDateTime)
        let endTimeString = DateFormatter.shortTimeFormatter().string(from: endDateTime)
        template.body2TextProvider = CLKSimpleTextProvider(text: "\(startTimeString) - \(endTimeString)" )
        
        return template
    }
    
    private func newGraphicRectangularTextGauge(with event: Event) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicRectangularTextGauge()
        
        let startDateTime = event.startDateTime(onDate: event.date!)
        let endDateTime = event.endDateTime(onDate: event.date!)

        template.headerImageProvider = appIconProvider(normalSize: false)
        template.headerTextProvider = CLKSimpleTextProvider(text: event.desc)
        template.headerTextProvider.tintColor = .purple
        
        let startTimeString = DateFormatter.shortTimeFormatter().string(from: startDateTime)
        let endTimeString = DateFormatter.shortTimeFormatter().string(from: endDateTime)
        
        let part1 = CLKSimpleTextProvider(text: startTimeString)
        part1.tintColor = .cyan
        let part2 = CLKSimpleTextProvider(text: " - ")
        part2.tintColor = .yellow
        let part3 = CLKSimpleTextProvider(text: endTimeString)
        part3.tintColor = .red
        template.body1TextProvider = CLKTextProvider(format: "%@%@%@", part1, part2, part3)
        
        template.gaugeProvider = timeIntervalGaugeProvider(start: startDateTime, end: endDateTime)
        return template
    }
}

// MARK: - Utilities
//
extension ComplicationController {
    
    // The large image size (pixel) is 300x94 for 40mm screen devices and 342x108 for 44mm screen devices.
    // This sample rounds the size a bit to fit the background pattern.
    //
    private func largeImageSize() -> CGSize {
        switch WKInterfaceDevice.current().screenBounds.size {
        case CGSize(width: 184, height: 224): // 44mm screen
            return CGSize(width: 170, height: 50)
        default: // 40mm screen
            return CGSize(width: 150, height: 45)
        }
    }
    
    // Generate an pattern image on the fly.
    //
    private func largeImage(for event: Event) -> UIImage {
        let size = largeImageSize()
        UIGraphicsBeginImageContextWithOptions(size, true, 0.0)

        guard let context = UIGraphicsGetCurrentContext() else {
            fatalError("Failed to get current context with UIGraphicsGetCurrentContext().")
        }
        
        // Fill the background with purple color.
        let rect = CGRect(origin: CGPoint(x: 0, y: 0), size: size)
        UIColor.purple.setFill()
        context.fill(rect)

        // Generate the pattern.
        let drawPattern: CGPatternDrawPatternCallback = { _, context in
            context.addArc( center: CGPoint(x: 5, y: 5), radius: 5,
                            startAngle: 0, endAngle: CGFloat(2.0 * .pi), clockwise: false)
            context.setFillColor(UIColor.black.cgColor)
            context.fillPath()
        }
        var callbacks = CGPatternCallbacks(version: 0, drawPattern: drawPattern, releaseInfo: nil)
        let pattern = CGPattern( info: nil, bounds: CGRect(x: 0, y: 0, width: 10, height: 10),
                                 matrix: .identity, xStep: 10, yStep: 10,
                                 tiling: .constantSpacing, isColored: true, callbacks: &callbacks)
        let patternSpace = CGColorSpace(patternBaseSpace: nil)!
        context.setFillColorSpace(patternSpace)

        var alpha: CGFloat = 1.0
        context.setFillPattern(pattern!, colorComponents: &alpha)
        context.fill(rect)
        
        // Draw the event name.
        let font = UIFont.boldSystemFont(ofSize: 12)
        let attributes: [NSAttributedString.Key: Any] = [.font: font,
                                                         .foregroundColor: UIColor.purple,
                                                         .backgroundColor: UIColor.black]
        let attributedString = NSAttributedString(string: event.name, attributes: attributes)
        attributedString.draw(at: CGPoint(x: size.width / 2 - 10, y: size.height / 2 - 10))

        // Grab the image from the context.
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            fatalError("Failed to get image with UIGraphicsGetImageFromCurrentImageContext().")
        }
        UIGraphicsEndImageContext()
        return image
    }
}

