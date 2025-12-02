/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Functions that convert a summary of activity statistics into data usable by other apps.
*/

import AppIntents
import CoreTransferable

#if canImport(UIKIt)
import UIKit

/**
 To share an `AppEntity` with other apps, conform it to `Transferable`. Consult the
 [Core Transferable documentation](https://developer.apple.com/documentation/coretransferable)
 for details on how to order the contents of the `transferRepresentation` property.
 
 To run this code, create a shortcut in the Shortcuts app with the Summarize Activities action. To see the rich-text formatting, connect the output of
 this action to the Make Image with Rich Text action, and set the Type of the input to this action to be Rich Text. To see the PNG
 representation, connect the output of the Summarize Activities action to the Append to Note action, and set the type to Image.
 */
extension ActivityStatisticsSummary: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .rtf) { summary in
            try summary.richTextRepresentation
        }

        FileRepresentation(exportedContentType: .png) { summary in
            SentTransferredFile(try summary.imageFileRepresentation, allowAccessingOriginalFile: true)
        }
    }

    /// - Returns: The text of the summary with an applied text-formatting style.
    private var formattedSummary: AttributedString {
        let distanceStyle = Measurement<UnitLength>.FormatStyle(width: .abbreviated, usage: .road)
        let calStyle = Measurement<UnitEnergy>.FormatStyle(width: .abbreviated, usage: .food)

        var string = AttributedString("""
            Activity Summary

            Total Workouts Completed: \(workoutsCompleted)
            Total Calories Burned:    \(caloriesBurned.formatted(calStyle))
            Distance Travelled:       \(distanceTraveled.formatted(distanceStyle))
        """)

        string.font = .systemFont(ofSize: 12, weight: .regular)

        if let range = string.range(of: "Activity Summary") {
            string[range].font = .systemFont(ofSize: 16, weight: .bold)
        }

        return string
    }

    /// - Returns: A `Data` object with the summary in a rich-text format.
    private var richTextRepresentation: Data {
        get throws {
            let attributedString = NSAttributedString(formattedSummary)
            return try attributedString.data(
                from: NSRange(location: 0, length: attributedString.length),
                documentAttributes: [
                    .documentType: NSAttributedString.DocumentType.rtf,
                    .characterEncoding: String.Encoding.utf8
                ]
            )
        }
    }
    
    /// - Returns: A `UIImage` with the rendered summary.
    private func textToImage(drawText text: AttributedString) -> UIImage {
        let bounds = CGSize(width: 250, height: 100)

        let renderer = UIGraphicsImageRenderer(size: bounds)
        let img = renderer.image { ctx in
            let backgroundColor = #colorLiteral(red: 0.8259537816, green: 1, blue: 0.8045250773, alpha: 1)
            backgroundColor.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height))

            let attributedString = NSAttributedString(text)
            attributedString.draw(with: CGRect(x: 15, y: 15, width: bounds.width - 15, height: bounds.height - 15),
                                  options: .usesLineFragmentOrigin,
                                  context: nil)
        }
        return img
    }

    /// - Returns: A URL to an image file with the rendered summary.
    private var imageFileRepresentation: URL {
        get throws {
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("activitysummary")
                .appendingPathExtension("png")

            let image = textToImage(drawText: formattedSummary)
            let data = image.pngData()
            try data?.write(to: url)
            return url
        }
    }
}
#endif // canImport(UIKit)
