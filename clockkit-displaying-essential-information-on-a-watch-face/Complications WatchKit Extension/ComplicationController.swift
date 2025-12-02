/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The complication controller of the watch app.
*/

import WatchKit
import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    // MARK: - Timeline Configuration
    //
    func getSupportedTimeTravelDirections(for complication: CLKComplication,
                                          withHandler handler: @escaping (CLKComplicationTimeTravelDirections) -> Void) {
        handler([.forward])
    }

    // The end date time of current timeline, which is the endDateTime of the last event in the next day.
    func getTimelineEndDate(for complication: CLKComplication,
                            withHandler handler: @escaping (Date?) -> Void) {
        let delegate: ExtensionDelegate! = WKExtension.shared().delegate as? ExtensionDelegate
        let endDateTime = delegate.timeline.endDateTime(after: Date())
        handler(endDateTime)
    }

    // This app uses the default .showOnLockScreen option as it does not handle any private data.
    // Consider using .hideOnLock when the complications contain personal information.
    //
    func getPrivacyBehavior(for complication: CLKComplication,
                            withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        handler(.showOnLockScreen)
    }
    
    // MARK: - Timeline Population
    //
    func getCurrentTimelineEntry(for complication: CLKComplication,
                                 withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let delegate: ExtensionDelegate! = WKExtension.shared().delegate as? ExtensionDelegate
        guard let event = delegate.timeline.event(at: Date()),
            let template = newTemplate(for: complication, configuration: delegate.templateConfiguration, event: event)
            else {
                return handler(nil)
        }
        let entry = CLKComplicationTimelineEntry(date: event.startDateTime(onDate: event.date!),
                                                 complicationTemplate: template)
        handler(entry)
    }
        
    // Provide events in the timeline, and the system will automatically progress through them.
    // When the system progresses through a reasonable amount data (a days worth, for example), it will wake up the app
    // and call this method again to get more entries.
    //
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int,
                            withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        let entries = nextDayEntries(for: complication, after: date, limit: limit)
        handler(entries)
    }
    
    private func nextDayEntries(for complication: CLKComplication, after date: Date, limit: Int) -> [CLKComplicationTimelineEntry] {
        let delegate: ExtensionDelegate! = WKExtension.shared().delegate as? ExtensionDelegate
        let events = delegate.timeline.nextDayEvents(after: date)
        
        var entries = [CLKComplicationTimelineEntry]()
        for event in events where entries.count < limit {
            if let template = newTemplate(for: complication, configuration: delegate.templateConfiguration, event: event) {
                let startDateTime = event.startDateTime(onDate: event.date!)
                entries.append(CLKComplicationTimelineEntry(date: startDateTime, complicationTemplate: template))
            }
        }
        return entries
    }
    
    // MARK: - Placeholder Templates
    // This sample uses the current event to create sample templates because Internationalization isn't its focus.
    // Real-world apps that support multiple languages should provide localized templates with fake data.
    // See the "Create Localized Placeholders" section in the following article for details:
    // https://developer.apple.com/documentation/clockkit/adding_a_complication_to_your_watchos_app/adding_placeholders_for_your_complication
    //
    func getLocalizableSampleTemplate(for complication: CLKComplication,
                                      withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        let delegate: ExtensionDelegate! = WKExtension.shared().delegate as? ExtensionDelegate
        guard let event = delegate.timeline.event(at: Date()) else {
            return handler(nil)
        }
        handler(newTemplate(for: complication, configuration: delegate.templateConfiguration, event: event))
    }
}

extension ComplicationController {
    func newTemplate(for complication: CLKComplication, configuration: TemplateConfiguration, event: Event) -> CLKComplicationTemplate? {
        switch complication.family {
            
        case .graphicBezel:
            return newGraphicBezelCircularText(with: event)

        case .graphicCorner:
            return newGraphicCornerTemplate(variant: GraphicCornerVariant(rawValue: configuration.graphicCorner)!, event: event)

        case .graphicCircular:
            return newGraphicCircularTemplate(variant: GraphicCircularVariant(rawValue: configuration.graphicCircular)!, event: event)

        case .graphicRectangular:
            return newGraphicRectangleTemplate(variant: GraphicRectangleVariant(rawValue: configuration.graphicRectangle)!, event: event)
            
        default:
            print("Unsupported familiy: \(complication.family.rawValue)!")
            return nil
        }
    }
}
