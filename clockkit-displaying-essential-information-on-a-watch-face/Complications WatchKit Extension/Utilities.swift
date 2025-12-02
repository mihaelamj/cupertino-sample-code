/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension to provide common utilities used in all templates.
*/

import ClockKit

extension ComplicationController {
    
    // This sample provides a normal and small size image to roughly fit all the complications.
    // A real-world app should consider providing accurately sized images for different purposes,
    // or a single scaleable PDF asset.
    //
    func appIconProvider(normalSize: Bool = true) -> CLKFullColorImageProvider {
        let fullColorImageName = normalSize ? "AppIcon" : "AppIconSmall"
        let tintForegroundName = normalSize ? "AppIconTemplate" : "AppIconTemplateSmall"
        let tintBackgroundName = normalSize ? "Transparent" : "TransparentSmall"
        
        guard let fullColorImage = UIImage(named: fullColorImageName), let tintForground = UIImage(named: tintForegroundName),
            let tintBackground = UIImage(named: tintBackgroundName) else {
            fatalError("Failed to load app icon (normalSize \(normalSize)).")
        }
        
        let tintedImageProvider = CLKImageProvider(onePieceImage: tintForground,
                                                   twoPieceImageBackground: tintBackground,
                                                   twoPieceImageForeground: tintForground)
        let fullColorImageProvider = CLKFullColorImageProvider(fullColorImage: fullColorImage,
                                                               tintedImageProvider: tintedImageProvider)
        return fullColorImageProvider
    }
    
    func timeIntervalGaugeProvider(start: Date, end: Date) -> CLKTimeIntervalGaugeProvider {
        return CLKTimeIntervalGaugeProvider(style: .fill, gaugeColors: [.cyan, .yellow, .red],
                                            gaugeColorLocations: [0, 0.5, 1], start: start, end: end)
    }
}
