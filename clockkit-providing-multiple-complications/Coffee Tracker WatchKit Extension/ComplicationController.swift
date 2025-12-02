/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A controller that configures and updates the complications.
*/

import ClockKit

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    // A structure that contains the identifier and display name for a specific
    // complication.
    struct Complication {
        let identifier: String
        let displayName: String
        
        static let caffeine = Complication(identifier: "Coffee_Tracker_Caffeine_Dose", displayName: "Caffeine Dose")
        static let cups = Complication(identifier: "Coffee_Tracker_Number_Of_Cups", displayName: "Total Cups")
        static let both = Complication(identifier: "Coffee_Tracker_Both", displayName: "Both Caffeine and Cups")
    }
    
    // The data property contains a reference to the app's shared data model.
    lazy var data = CoffeeData.shared
    
    // MARK: - Timeline Configuration
    
    // Define how far into the future the app can provide data.
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Indicate that the app can provide timeline entries for the next 24 hours.
        handler(Date().addingTimeInterval(24.0 * 60.0 * 60.0))
    }
    
    // Define whether the complication is visible when the watch is unlocked.
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // This is potentially sensitive data. Hide it on the lock screen.
        handler(.hideOnLockScreen)
    }
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        
        // Create the descriptor for complications that show the current caffeine dose.
        let caffeine = CLKComplicationDescriptor(
            identifier: Complication.caffeine.identifier,
            displayName: Complication.caffeine.displayName,
            supportedFamilies: [.modularSmall,
                                .utilitarianSmall,
                                .utilitarianSmallFlat,
                                .utilitarianLarge,
                                .circularSmall,
                                .extraLarge,
                                .graphicCorner,
                                .graphicCircular,
                                .graphicRectangular,
                                .graphicExtraLarge])
        
        // Create the descriptor for complications that show the equivalent number
        // of 8-ounce cups drank today.
        let cups = CLKComplicationDescriptor(
            identifier: Complication.cups.identifier,
            displayName: Complication.cups.displayName,
            supportedFamilies: [.modularSmall,
                                .utilitarianSmall,
                                .utilitarianSmallFlat,
                                .utilitarianLarge,
                                .circularSmall,
                                .extraLarge,
                                .graphicCorner,
                                .graphicCircular,
                                .graphicRectangular,
                                .graphicExtraLarge])
        
        // Create the descriptor for complications that show both the current caffeine
        // dose and the total number of cups drank.
        let both = CLKComplicationDescriptor(identifier: Complication.both.identifier,
                                             displayName: Complication.both.displayName,
                                             supportedFamilies: [.modularLarge, .graphicBezel])
        
        handler([both, caffeine, cups])
    }
    
    // MARK: - Timeline Population
    
    // Return the current timeline entry.
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        handler(createTimelineEntry(forComplication: complication, date: Date()))
    }
    
    // Return future timeline entries.
    func getTimelineEntries(for complication: CLKComplication,
                            after date: Date,
                            limit: Int,
                            withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        
        let fiveMinutes = 5.0 * 60.0
        let twentyFourHours = 24.0 * 60.0 * 60.0
        
        // Create an array to hold the timeline entries.
        var entries = [CLKComplicationTimelineEntry]()
        
        // Calculate the start and end dates.
        var current = date.addingTimeInterval(fiveMinutes)
        let endDate = date.addingTimeInterval(twentyFourHours)
        
        // Create a timeline entry for every five minutes from the starting time.
        // Stop once you reach the limit or the end date.
        while (current.compare(endDate) == .orderedAscending) && (entries.count < limit) {
            entries.append(createTimelineEntry(forComplication: complication, date: current))
            current = current.addingTimeInterval(fiveMinutes)
        }
        
        handler(entries)
    }
    
    // MARK: - Placeholder Templates
    
    // Return a localized template with generic information. The system displays
    // the placeholder in the complication selector.
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // Calculate the date 25 hours from now. Because it's more than 24 hours
        // in the future, our template will always show zero cups and zero mg caffeine.
        let future = Date().addingTimeInterval(25.0 * 60.0 * 60.0)
        let template = createTemplate(forComplication: complication, date: future)
        handler(template)
    }
    
    //  We don't need to implement this method because our privacy behavior is
    //  hideOnLockScreen. Always-On Time automatically hides complications that
    //  would be hidden when the device is locked.
    
//    func getAlwaysOnTemplate(for complication: CLKComplication,
//                             withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
//    }
    
    // MARK: - Private Methods
    
    // Return a timeline entry for the specified complication and date.
    private func createTimelineEntry(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTimelineEntry {
        
        // Get the correct template based on the complication.
        let template = createTemplate(forComplication: complication, date: date)
        
        // Use the template and date to create a timeline entry.
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }
    
    // Select the correct template based on the complication's family.
    private func createTemplate(forComplication complication: CLKComplication, date: Date) -> CLKComplicationTemplate {
        
        switch (complication.family, complication.identifier) {
        
        case (.modularSmall, Complication.cups.identifier):
            return createCupsModularSmallTemplate(forDate: date)
        case (.modularSmall, _):
            return createCaffeineModularSmallTemplate(forDate: date)
        
        case (.modularLarge, _):
            return createBothModularLargeTemplate(forDate: date)
            
        case (.utilitarianSmall, Complication.cups.identifier),
             (.utilitarianSmallFlat, Complication.cups.identifier):
            return createCupsUtilitarianSmallFlatTemplate(forDate: date)
        case (.utilitarianSmall, _),
             (.utilitarianSmallFlat, _):
            return createCaffeineUtilitarianSmallFlatTemplate(forDate: date)
        case (.utilitarianLarge, Complication.cups.identifier):
            return createCupsUtilitarianLargeTemplate(forDate: date)
        case (.utilitarianLarge, _):
            return createCaffeineUtilitarianLargeTemplate(forDate: date)
        case (.circularSmall, Complication.cups.identifier):
            return createCupsCircularSmallTemplate(forDate: date)
        case (.circularSmall, _):
            return createCaffeineCircularSmallTemplate(forDate: date)
        case (.extraLarge, Complication.cups.identifier):
            return createCupsExtraLargeTemplate(forDate: date)
        case (.extraLarge, _):
            return createCaffeineExtraLargeTemplate(forDate: date)
        case (.graphicCorner, Complication.cups.identifier):
            return createCupsGraphicCornerTemplate(forDate: date)
        case (.graphicCorner, _):
            return createCaffeineGraphicCornerTemplate(forDate: date)
        case (.graphicCircular, Complication.cups.identifier):
            return createCupsGraphicCircleTemplate(forDate: date)
        case (.graphicCircular, _):
            return createCaffeineGraphicCircleTemplate(forDate: date)
        case (.graphicRectangular, Complication.cups.identifier):
            return createCupsGraphicRectangularTemplate(forDate: date)
        case (.graphicRectangular, _):
            return createCaffeineGraphicRectangularTemplate(forDate: date)
        case (.graphicBezel, _):
            return createBothGraphicBezelTemplate(forDate: date)
        case (.graphicExtraLarge, Complication.cups.identifier):
            return createCupsGraphicExtraLargeTemplate(forDate: date)
        case (.graphicExtraLarge, _):
            return createCaffeineGraphicExtraLargeTemplate(forDate: date)
        @unknown default:
            fatalError("*** Unknown Family and identifier pair: (\(complication.family), \(complication.identifier)) ***")
        }
    }
    // MARK: - Modular Small Templates
    
    private func createCaffeineModularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        
        // Create the template using the providers.
        return CLKComplicationTemplateModularSmallStackText(line1TextProvider: mgCaffeineProvider,
                                                            line2TextProvider: mgUnitProvider)
    }
    
    private func createCupsModularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let numberOfCupsProvider = CLKSimpleTextProvider(text: data.totalCupsTodayString)
        let cupsUnitProvider = CLKSimpleTextProvider(text: "Cups", shortText: "C")
        
        // Create the template using the providers.
        return CLKComplicationTemplateModularSmallStackText(line1TextProvider: numberOfCupsProvider,
                                                            line2TextProvider: cupsUnitProvider)
    }
    
    // MARK: - Modular Large Template
    
    private func createBothModularLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let titleTextProvider = CLKSimpleTextProvider(text: "Coffee Tracker", shortText: "Coffee")

        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
               
        let numberOfCupsProvider = CLKSimpleTextProvider(text: data.totalCupsTodayString)
        let cupsUnitProvider = CLKSimpleTextProvider(text: "Cups", shortText: "C")
        let combinedCupsProvider = CLKTextProvider(format: "%@ %@", numberOfCupsProvider, cupsUnitProvider)
        
        // Create the template using the providers.
        let imageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeModularLarge"))
        return CLKComplicationTemplateModularLargeStandardBody(headerImageProvider: imageProvider,
                                                               headerTextProvider: titleTextProvider,
                                                               body1TextProvider: combinedCupsProvider,
                                                               body2TextProvider: combinedMGProvider)
    }
    
    // MARK: - Utilitarian Small Flat Template
    
    private func createCaffeineUtilitarianSmallFlatTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let flatUtilitarianImageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeSmallFlat"))
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
        
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: combinedMGProvider,
                                                           imageProvider: flatUtilitarianImageProvider)
    }
    
    private func createCupsUtilitarianSmallFlatTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let flatUtilitarianImageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeSmallFlat"))
        
        let numberOfCupsProvider = CLKSimpleTextProvider(text: data.totalCupsTodayString)
        let cupsUnitProvider = CLKSimpleTextProvider(text: "Cups", shortText: "C")
        let combinedCupsProvider = CLKTextProvider(format: "%@ %@", numberOfCupsProvider, cupsUnitProvider)
        
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianSmallFlat(textProvider: combinedCupsProvider,
                                                           imageProvider: flatUtilitarianImageProvider)
    }
    
    // MARK: - Utilitarian Large Template
    
    private func createCaffeineUtilitarianLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let flatUtilitarianImageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeSmallFlat"))
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
        
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: combinedMGProvider,
                                                           imageProvider: flatUtilitarianImageProvider)
    }
    
    private func createCupsUtilitarianLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let flatUtilitarianImageProvider = CLKImageProvider(onePieceImage: #imageLiteral(resourceName: "CoffeeSmallFlat"))
        
        let numberOfCupsProvider = CLKSimpleTextProvider(text: data.totalCupsTodayString)
        let cupsUnitProvider = CLKSimpleTextProvider(text: "Cups", shortText: "C")
        let combinedCupsProvider = CLKTextProvider(format: "%@ %@", numberOfCupsProvider, cupsUnitProvider)
        
        // Create the template using the providers.
        return CLKComplicationTemplateUtilitarianLargeFlat(textProvider: combinedCupsProvider,
                                                           imageProvider: flatUtilitarianImageProvider)
    }
    
    // MARK: - Circular Small Template
    
    private func createCaffeineCircularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        
        // Create the template using the providers.
        return CLKComplicationTemplateCircularSmallStackText(line1TextProvider: mgCaffeineProvider,
                                                             line2TextProvider: mgUnitProvider)
    }
    
    private func createCupsCircularSmallTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let numberOfCupsProvider = CLKSimpleTextProvider(text: data.totalCupsTodayString)
        let cupsUnitProvider = CLKSimpleTextProvider(text: "Cups", shortText: "C")
        
        // Create the template using the providers.
        return CLKComplicationTemplateCircularSmallStackText(line1TextProvider: numberOfCupsProvider,
                                                             line2TextProvider: cupsUnitProvider)
    }
    
    // MARK: - Extra Large Template
    
    private func createCaffeineExtraLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg")
        
        // Create the template using the providers.
        return CLKComplicationTemplateExtraLargeStackText(line1TextProvider: mgCaffeineProvider,
                                                          line2TextProvider: mgUnitProvider)
    }
    
    private func createCupsExtraLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let numberOfCupsProvider = CLKSimpleTextProvider(text: data.totalCupsTodayString)
        let cupsUnitProvider = CLKSimpleTextProvider(text: "Cups", shortText: "C")
        
        // Create the template using the providers.
        return CLKComplicationTemplateExtraLargeStackText(line1TextProvider: numberOfCupsProvider,
                                                          line2TextProvider: cupsUnitProvider)
    }
    
    // MARK: - Graphic Corner Template
    
    private func createCaffeineGraphicCornerTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let leadingValueProvider = CLKSimpleTextProvider(text: "0")
        leadingValueProvider.tintColor = data.color(forCaffeineDose: 0.0)
        
        let trailingValueProvider = CLKSimpleTextProvider(text: "500")
        trailingValueProvider.tintColor = data.color(forCaffeineDose: 500.0)
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
        
        let percentage = Float(min(data.mgCaffeine(atDate: date) / 500.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 300.0 / 500.0, 450.0 / 500.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCornerGaugeText(gaugeProvider: gaugeProvider,
                                                             leadingTextProvider: leadingValueProvider,
                                                             trailingTextProvider: trailingValueProvider,
                                                             outerTextProvider: combinedMGProvider)
    }
    
    private func createCupsGraphicCornerTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let leadingValueProvider = CLKSimpleTextProvider(text: "0")
        leadingValueProvider.tintColor = data.color(forTotalCups: 0.0)
        
        let trailingValueProvider = CLKSimpleTextProvider(text: "6")
        trailingValueProvider.tintColor = data.color(forTotalCups: 6.0)
        
        let numberOfCupsProvider = CLKSimpleTextProvider(text: data.totalCupsTodayString)
        let cupsUnitProvider = CLKSimpleTextProvider(text: "Cups", shortText: "C")
        let combinedCupsProvider = CLKTextProvider(format: "%@ %@", numberOfCupsProvider, cupsUnitProvider)
        
        let percentage = Float(min(data.totalCupsToday / 6.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 3.0 / 6.0, 5.5 / 6.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCornerGaugeText(gaugeProvider: gaugeProvider,
                                                             leadingTextProvider: leadingValueProvider,
                                                             trailingTextProvider: trailingValueProvider,
                                                             outerTextProvider: combinedCupsProvider)
    }
    
    // MARK: - Graphic Circle Template
    
    private func createCaffeineGraphicCircleTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let percentage = Float(min(data.mgCaffeine(atDate: date) / 500.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 300.0 / 500.0, 450.0 / 500.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        mgUnitProvider.tintColor = data.color(forCaffeineDose: data.mgCaffeine(atDate: date))
        
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText(gaugeProvider: gaugeProvider,
                                                                         bottomTextProvider: mgUnitProvider,
                                                                         centerTextProvider: mgCaffeineProvider)
    }
    
    private func createCupsGraphicCircleTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let percentage = Float(min(data.totalCupsToday / 6.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 3.0 / 6.0, 5.5 / 6.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        let numberOfCupsProvider = CLKSimpleTextProvider(text: data.totalCupsTodayString)
        let cupsUnitProvider = CLKSimpleTextProvider(text: "Cups", shortText: "C")
        cupsUnitProvider.tintColor = data.color(forTotalCups: data.totalCupsToday)
        
        // Create the template using the providers.
        return CLKComplicationTemplateGraphicCircularOpenGaugeSimpleText(gaugeProvider: gaugeProvider,
                                                                         bottomTextProvider: cupsUnitProvider,
                                                                         centerTextProvider: numberOfCupsProvider)
    }
    
    // MARK: - Graphic Rectangular Template
    
    private func createCaffeineGraphicRectangularTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let imageProvider = CLKFullColorImageProvider(fullColorImage: #imageLiteral(resourceName: "CoffeeGraphicRectangular"))
        let titleTextProvider = CLKSimpleTextProvider(text: "Coffee Tracker", shortText: "Coffee")
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        mgUnitProvider.tintColor = data.color(forCaffeineDose: data.mgCaffeine(atDate: date))
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
        
        let percentage = Float(min(data.mgCaffeine(atDate: date) / 500.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 300.0 / 500.0, 450.0 / 500.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        // Create the template using the providers.
        
        return CLKComplicationTemplateGraphicRectangularTextGauge(headerImageProvider: imageProvider,
                                                                  headerTextProvider: titleTextProvider,
                                                                  body1TextProvider: combinedMGProvider,
                                                                  gaugeProvider: gaugeProvider)
    }
    
    private func createCupsGraphicRectangularTemplate(forDate date: Date) -> CLKComplicationTemplate {
        // Create the data providers.
        let imageProvider = CLKFullColorImageProvider(fullColorImage: #imageLiteral(resourceName: "CoffeeGraphicRectangular"))
        let titleTextProvider = CLKSimpleTextProvider(text: "Coffee Tracker", shortText: "Coffee")
        
        let numberOfCupsProvider = CLKSimpleTextProvider(text: data.totalCupsTodayString)
        let cupsUnitProvider = CLKSimpleTextProvider(text: "Cups", shortText: "C")
        cupsUnitProvider.tintColor = data.color(forTotalCups: data.totalCupsToday)
        let combinedCupsProvider = CLKTextProvider(format: "%@ %@", numberOfCupsProvider, cupsUnitProvider)
        
        let percentage = Float(min(data.totalCupsToday / 6.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 3.0 / 6.0, 5.5 / 6.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        // Create the template using the providers.
        
        return CLKComplicationTemplateGraphicRectangularTextGauge(headerImageProvider: imageProvider,
                                                                  headerTextProvider: titleTextProvider,
                                                                  body1TextProvider: combinedCupsProvider,
                                                                  gaugeProvider: gaugeProvider)
    }
    
    // MARK: - Graphic Bezel Template
    
    private func createBothGraphicBezelTemplate(forDate date: Date) -> CLKComplicationTemplate {
        
        // Create a graphic circular template with an image provider.
        let circle = CLKComplicationTemplateGraphicCircularImage(imageProvider: CLKFullColorImageProvider(fullColorImage: #imageLiteral(resourceName: "CoffeeGraphicCircular")))
        
        // Create the text provider.
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        let combinedMGProvider = CLKTextProvider(format: "%@ %@", mgCaffeineProvider, mgUnitProvider)
               
        let numberOfCupsProvider = CLKSimpleTextProvider(text: data.totalCupsTodayString)
        let cupsUnitProvider = CLKSimpleTextProvider(text: "Cups", shortText: "C")
        let combinedCupsProvider = CLKTextProvider(format: "%@ %@", numberOfCupsProvider, cupsUnitProvider)
        
        let separator = NSLocalizedString(",", comment: "Separator for compound data strings.")
        let textProvider = CLKTextProvider(format: "%@%@ %@",
                                           combinedMGProvider,
                                           separator,
                                           combinedCupsProvider)
        
        // Create the bezel template using the circle template and the text provider.
        return CLKComplicationTemplateGraphicBezelCircularText(circularTemplate: circle,
                                                               textProvider: textProvider)
    }
    
    // MARK: - Graphic Extra Large Template
    
    private func createCaffeineGraphicExtraLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        
        // Create the data providers.
        let percentage = Float(min(data.mgCaffeine(atDate: date) / 500.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 300.0 / 500.0, 450.0 / 500.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        let mgCaffeineProvider = CLKSimpleTextProvider(text: data.mgCaffeineString(atDate: date))
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        mgUnitProvider.tintColor = data.color(forCaffeineDose: data.mgCaffeine(atDate: date))
        
        return CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeSimpleText(
            gaugeProvider: gaugeProvider,
            bottomTextProvider: mgUnitProvider,
            centerTextProvider: mgCaffeineProvider)
    }
    
    private func createCupsGraphicExtraLargeTemplate(forDate date: Date) -> CLKComplicationTemplate {
        
        // Create the data providers.
        let percentage = Float(min(data.totalCupsToday / 6.0, 1.0))
        let gaugeProvider = CLKSimpleGaugeProvider(style: .fill,
                                                   gaugeColors: [.green, .yellow, .red],
                                                   gaugeColorLocations: [0.0, 3.0 / 6.0, 5.5 / 6.0] as [NSNumber],
                                                   fillFraction: percentage)
        
        let numberOfCupsProvider = CLKSimpleTextProvider(text: data.totalCupsTodayString)
        let cupsUnitProvider = CLKSimpleTextProvider(text: "Cups", shortText: "C")
        cupsUnitProvider.tintColor = data.color(forTotalCups: data.totalCupsToday)
        
        return CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeSimpleText(
            gaugeProvider: gaugeProvider,
            bottomTextProvider: cupsUnitProvider,
            centerTextProvider: numberOfCupsProvider)
    }
}
