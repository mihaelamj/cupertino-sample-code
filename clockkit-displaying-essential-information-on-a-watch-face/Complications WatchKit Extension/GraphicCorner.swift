/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension to provide a Graphic Corner template.
*/

import Foundation
import ClockKit

// MARK: - Graphic Corner family
//
extension ComplicationController {
    func newGraphicCornerTemplate(variant: GraphicCornerVariant, event: Event) -> CLKComplicationTemplate {
        switch variant {
            
        case .circularImage:
            return newGraphicCornerCircularImage(with: event)
            
        case .gaugeImage:
            return newGraphicCornerGaugeImage(with: event)
            
        case .gaugeText:
            return newGraphicCornerGaugeText(with: event)
            
        case .textImage:
            return newGraphicCornerTextImage(with: event)
            
        case .stackText:
            return newGraphicCornerStackText(with: event)
        }
    }

    private func newGraphicCornerGaugeText(with event: Event) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCornerGaugeText()
        
        let startDateTime = event.startDateTime(onDate: event.date!)
        let endDateTime = event.endDateTime(onDate: event.date!)

        let components = Calendar.current.dateComponents([.minute], from: startDateTime, to: endDateTime)
        let minuteDiff = components.minute!

        template.leadingTextProvider = CLKSimpleTextProvider(text: "0")
        template.leadingTextProvider?.tintColor = .cyan
        template.trailingTextProvider = CLKSimpleTextProvider(text: String(minuteDiff))
        template.trailingTextProvider?.tintColor = .red
        template.outerTextProvider = CLKRelativeDateTextProvider(date: endDateTime, style: .timer,
                                                                 units: [.minute])
        template.gaugeProvider = timeIntervalGaugeProvider(start: startDateTime, end: endDateTime)
        return template
    }
    
    private func newGraphicCornerGaugeImage(with event: Event) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCornerGaugeImage()

        let startDateTime = event.startDateTime(onDate: event.date!)
        let endDateTime = event.endDateTime(onDate: event.date!)

        template.leadingTextProvider = CLKRelativeDateTextProvider(date: startDateTime,
                                                                   style: .offsetShort,
                                                                   units: [.minute])
        template.leadingTextProvider?.tintColor = .cyan
        template.trailingTextProvider = CLKSimpleTextProvider(text: "")
        template.gaugeProvider = timeIntervalGaugeProvider(start: startDateTime, end: endDateTime)
        template.imageProvider = appIconProvider(normalSize: false)
        return template
    }
    
    private func newGraphicCornerTextImage(with event: Event) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCornerTextImage()
        template.textProvider = CLKRelativeDateTextProvider(date: event.startDateTime(onDate: Date()),
                                                            style: .timer,
                                                            units: [.hour, .minute, .second])
        template.textProvider.tintColor = .orange
        template.imageProvider = appIconProvider(normalSize: false)
        return template
    }
    
    private func newGraphicCornerStackText(with event: Event) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCornerStackText()
        template.outerTextProvider = CLKSimpleTextProvider(text: event.name)
        template.innerTextProvider = CLKRelativeDateTextProvider(date: event.startDateTime(onDate: Date()),
                                                                 style: .natural,
                                                                 units: [.hour, .minute, .second])
        template.innerTextProvider.tintColor = .orange
        return template
    }
    
    private func newGraphicCornerCircularImage(with event: Event) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCornerCircularImage()
        template.imageProvider = appIconProvider()
        return template
    }
}
