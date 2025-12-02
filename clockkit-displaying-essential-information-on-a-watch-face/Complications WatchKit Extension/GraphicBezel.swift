/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension to provide a Graphic Bezel template.
*/

import ClockKit

// MARK: - Graphic Bezel family
//
extension ComplicationController {
    func newGraphicBezelCircularText(with event: Event) -> CLKComplicationTemplate {
        let bezelTemplate = CLKComplicationTemplateGraphicBezelCircularText()
        
        let startDateTime = event.startDateTime(onDate: event.date!)
        let endDateTime = event.endDateTime(onDate: event.date!)
        
        let circularTemplate = CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText()
        circularTemplate.centerTextProvider = CLKSimpleTextProvider(text: "C")
        circularTemplate.centerTextProvider.tintColor = .purple
        circularTemplate.bottomTextProvider = CLKSimpleTextProvider(text: event.name)
        circularTemplate.bottomTextProvider.tintColor = .white
        circularTemplate.gaugeProvider = timeIntervalGaugeProvider(start: startDateTime, end: endDateTime)
        bezelTemplate.circularTemplate = circularTemplate
        
        let startTimeString = DateFormatter.shortTimeFormatter().string(from: startDateTime)
        let endTimeString = DateFormatter.shortTimeFormatter().string(from: endDateTime)
        bezelTemplate.textProvider = CLKSimpleTextProvider(text: "\(event.desc) \(startTimeString) - \(endTimeString)" )
        
        return bezelTemplate
    }
}
