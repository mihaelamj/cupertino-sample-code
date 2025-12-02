/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An NSManagedObject subclass for the Book entity.
*/

import UIKit
import CoreData

@objc(Book)
public class Book: NSManagedObject {

    struct Name {
        static let publishDate = "publishDate"
        static let publishMonthID = "publishMonthID"
    }

    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<Book> {
        return NSFetchRequest<Book>(entityName: "Book")
    }

    @NSManaged public var title: String?
    @NSManaged public var canonicalTitle: String?
    @NSManaged public var tintColor: UIColor?
    @NSManaged public var uuid: UUID?
    @NSManaged public var url: URL?
    @NSManaged public var abstract: Data?
    @NSManaged public var price: NSDecimalNumber?
    
    // Let Core Data generate accessors for primitivePublishMonthID and primitivePublishDate,
    // which are used in the custom accessors for publishMonthID and publishDate.
    //
    @NSManaged private var primitivePublishDate: Date?
    @NSManaged private var primitivePublishMonthID: String?

    // This sets up the key path dependency for publishMonthID,
    // allowing the observers of publishMonthID to get notified when its date changes.
    //
    class func keyPathsForValuesAffectingPublishMonthID() -> Set<String> {
        return [Name.publishDate]
    }

    // Provide a custom accessor to nullify primitivePublishMonthID so it is recalculated next time it is used.
    // Date is equivalent to TimeInterval, or Double; it is really a number of seconds since 1970.
    //
    @objc public var publishDate: Date? {
        get {
            willAccessValue(forKey: Name.publishDate)
            defer { didAccessValue(forKey: Name.publishDate) }
            return primitivePublishDate
        }
        set {
            willChangeValue(forKey: Name.publishDate)
            defer { didChangeValue(forKey: Name.publishDate) }
            primitivePublishDate = newValue
            primitivePublishMonthID = nil
        }
    }

    // Provide a custom accessor for publishMonthID.
    // @objc is required as this property is used as a key path in NSFetchedResultsController.
    // Use .gregorian calendar to make sure the formula (year * 1000 + month) is valid.
    //
    // Encode the year and month components to a string then decode and convert it to a section title because:
    // 1. publishMonthID is used in NSFetchedResultsController's sectionNameKeyPath, which requires the sections are
    //    sorted in the same order as the rows so they can be fetched in batch.
    // 2. TableView section title is a user-visible string from the year + month and changes based on the current
    //    system settings (calendar, locale, time zone), so we can't convert year + month directly to a title string.
    //
    @objc public var publishMonthID: String? {
        willAccessValue(forKey: Name.publishMonthID)
        defer { didAccessValue(forKey: Name.publishMonthID) }
        
        guard primitivePublishMonthID == nil, let date = primitivePublishDate else {
            return primitivePublishMonthID
        }
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: date)
        if let year = components.year, let month = components.month {
            primitivePublishMonthID = "\(year * 1000 + month)"
        }
        return primitivePublishMonthID
    }

    // Convert a publishMonthString, or the section name of the main table view, to a date.
    // Use the same calendar and time zone to decode the transient value.
    //
    class func date(from publishMonthString: String) -> Date? {
    
        guard let numericSection = Int(publishMonthString) else {
            return nil
        }
        var dateComponents = DateComponents()
        dateComponents.calendar = Calendar(identifier: .gregorian)

        let year = numericSection / 1000
        let month = numericSection - year * 1000
        dateComponents.year = year
        dateComponents.month = month
        
        return dateComponents.calendar?.date(from: dateComponents)
    }
}
