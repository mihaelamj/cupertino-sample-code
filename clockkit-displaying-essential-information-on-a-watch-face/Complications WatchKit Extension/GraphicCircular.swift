/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension to provide a Graphic Circular template.
*/

import ClockKit

// MARK: - Graphic Circular family
//
extension ComplicationController {
    func newGraphicCircularTemplate(variant: GraphicCircularVariant, event: Event) -> CLKComplicationTemplate {
        switch variant {
            
        case .image:
            return newGraphicCircularImage(with: event)
            
        case .openGaugeRangeText:
            return newGraphicCircularOpenGaugeRangeText(with: event)
            
        case .openGaugeSimpleText:
            return newGraphicCircularOpenGaugeSimpleText(with: event)
            
        case .openGaugeImage:
            return newGraphicCircularOpenGaugeImage(with: event)
            
        case .closedGaugeText:
            return newGraphicCircularClosedGaugeText(with: event)
            
        case .closedGaugeImage:
            return newGraphicCircularClosedGaugeImage(with: event)
        }
    }

    private func newGraphicCircularImage(with event: Event) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCircularImage()
        template.imageProvider = appIconProvider()
        return template
    }
    
    private func newGraphicCircularOpenGaugeRangeText(with event: Event) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCircularOpenGaugeRangeText()

        let startDateTime = event.startDateTime(onDate: event.date!)
        let endDateTime = event.endDateTime(onDate: event.date!)

        let components = Calendar.current.dateComponents([.minute], from: startDateTime, to: endDateTime)
        let minuteDiff = components.minute!
        
        template.leadingTextProvider = CLKSimpleTextProvider(text: "0")
        template.leadingTextProvider.tintColor = .cyan
        template.trailingTextProvider = CLKSimpleTextProvider(text: String(minuteDiff))
        template.trailingTextProvider.tintColor = .red
        template.centerTextProvider = CLKSimpleTextProvider(text: "C")
        template.centerTextProvider.tintColor = .purple
        template.gaugeProvider = timeIntervalGaugeProvider(start: startDateTime, end: endDateTime)
        return template
    }
    
    private func newGraphicCircularOpenGaugeSimpleText(with event: Event) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText()
        
        let startDateTime = event.startDateTime(onDate: event.date!)
        let endDateTime = event.endDateTime(onDate: event.date!)

        template.centerTextProvider = CLKSimpleTextProvider(text: "C")
        template.centerTextProvider.tintColor = .purple
        template.bottomTextProvider = CLKSimpleTextProvider(text: event.name)
        template.bottomTextProvider.tintColor = .white
        template.gaugeProvider = timeIntervalGaugeProvider(start: startDateTime, end: endDateTime)

        return template
    }
    
    private func newGraphicCircularOpenGaugeImage(with event: Event) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCircularOpenGaugeImage()
        
        let startDateTime = event.startDateTime(onDate: event.date!)
        let endDateTime = event.endDateTime(onDate: event.date!)

        template.centerTextProvider = CLKSimpleTextProvider(text: event.name)
        template.bottomImageProvider = appIconProvider(normalSize: false)
        template.gaugeProvider = timeIntervalGaugeProvider(start: startDateTime, end: endDateTime)
            
        return template
    }
    
    private func newGraphicCircularClosedGaugeText(with event: Event) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCircularClosedGaugeText()
        
        let startDateTime = event.startDateTime(onDate: event.date!)
        let endDateTime = event.endDateTime(onDate: event.date!)

        template.gaugeProvider = timeIntervalGaugeProvider(start: startDateTime, end: endDateTime)
        template.centerTextProvider = CLKSimpleTextProvider(text: event.name)
        template.centerTextProvider.tintColor = .purple
        return template
    }
    
    private func newGraphicCircularClosedGaugeImage(with event: Event) -> CLKComplicationTemplate {
        let template = CLKComplicationTemplateGraphicCircularClosedGaugeImage()
        
        let startDateTime = event.startDateTime(onDate: event.date!)
        let endDateTime = event.endDateTime(onDate: event.date!)

        template.imageProvider = appIconProvider()
        template.gaugeProvider = timeIntervalGaugeProvider(start: startDateTime, end: endDateTime)
        return template
    }
}
