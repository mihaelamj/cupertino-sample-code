/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A helper for generating sample data.
*/

import UIKit
import CoreData

struct SampleData {
    static private let abstracts = [
        "{\\rtf1\\ansi{\\fonttbl\\f0\\fswiss Helvetica;}\\f0\\pard {\\b Lorem ipsum dolor sit er elit lamet, consectetaur cillium adipisicing pecu, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.}\\par}",
        "{\\rtf1\\ansi{\\fonttbl\\f0\\fswiss Helvetica;}\\f0\\pard {\\i Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.}\\par}",
        "{\\rtf1\\ansi{\\fonttbl\\f0\\fswiss Helvetica;}\\f0\\pard {\\b Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.}\\par}",
        "{\\rtf1\\ansi{\\fonttbl\\f0\\fswiss Helvetica;}\\f0\\pard {\\i Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. Nam liber te conscient to factor tum poen legum odioque civiuda.}\\par}"
    ]
    
    // DateComponents() returns a DateComponents object with the current system time zone.
    // Use .gregorian and current time zone to set up date components and generate test data.
    // With a different calendar or time zone, a same set of date components will be mapped to a different date.
    //
    private static var dateComponents: DateComponents = {
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar(identifier: .gregorian)
        dateComponents.year = 2019
        return dateComponents
    }()
    
    static private func randomBookName(length: Int) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyzÂĆĒĪÑØŚÜŸ"
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    static private func generateOneNewBook(with dateComonents: DateComponents, context: NSManagedObjectContext) {
        let newBook = Book(context: context)
        
        // uuid: UUID
        //
        newBook.uuid = UUID()
        
        if let day = dateComonents.day {
            newBook.title = randomBookName(length: 10) + "-\(day)"
        }

        // publishDate: Date
        //
        if let date = dateComonents.calendar?.date(from: dateComonents) {
            newBook.publishDate = date
        }
        
        // price: Use NSDecimalNumber to handle currency value
        //
        let value = UInt64(arc4random_uniform(9999))
        newBook.price = NSDecimalNumber(mantissa: value, exponent: -2, isNegative: false)

        // color: UIColor, transformable
        //
        let red = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let green = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        let blue = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
        newBook.tintColor = UIColor(red: red, green: green, blue: blue, alpha: 1)
        
        // abstract: Data. Pretend the abstract is a piece of RTF data,
        //
        let index = Int(arc4random_uniform(UInt32(abstracts.count)))
        let rtfData = Data(abstracts[index].utf8)
        newBook.abstract = rtfData
        
        // url: URL
        // Most modern APIs interact with URL, rather than a path or URI string.
        // Use URI attribute to persist a URL object directly.
        //
        if let uuidString = newBook.uuid?.uuidString {
            newBook.url = URL(string: "http://example.com" + uuidString)
        }
    }
    
    static func generateSampleDataIfNeeded(context: NSManagedObjectContext) {
        context.perform {
            guard let number = try? context.count(for: Book.fetchRequest()), number == 0 else {
                return
            }
            for day in stride(from: 1, to: 365, by: 7) {
                dateComponents.day = day
                self.generateOneNewBook(with: dateComponents, context: context)
            }
            do {
                try context.save()
            } catch {
                print("Failed to saving test data: \(error)")
            }
        }
    }
}
