/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A collection of classes that define the Core Data stack that stores feed entries in the database.
*/

import Foundation
import CoreData

class PersistentContainer: NSPersistentContainer {
    private static let lastCleanedKey = "lastCleaned"

    static let shared: PersistentContainer = {
        ValueTransformer.setValueTransformer(ColorTransformer(), forName: NSValueTransformerName(rawValue: String(describing: ColorTransformer.self)))
        
        let container = PersistentContainer(name: "ColorFeed")
        container.loadPersistentStores { (desc, error) in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
            
            print("Successfully loaded persistent store at: \(desc.url?.description ?? "nil")")
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType)
        
        return container
    }()
    
    var lastCleaned: Date? {
        get {
            return UserDefaults.standard.object(forKey: PersistentContainer.lastCleanedKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: PersistentContainer.lastCleanedKey)
        }
    }
    
    override func newBackgroundContext() -> NSManagedObjectContext {
        let backgroundContext = super.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType)
        return backgroundContext
    }
}

// A platform-agnostic model object representing a color, suitable for persisting with Core Data
public class Color: NSObject, NSSecureCoding {
    public let red: Double
    public let green: Double
    public let blue: Double
    
    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        super.init()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        self.red = aDecoder.decodeDouble(forKey: "red")
        self.green = aDecoder.decodeDouble(forKey: "green")
        self.blue = aDecoder.decodeDouble(forKey: "blue")
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(red, forKey: "red")
        aCoder.encode(green, forKey: "green")
        aCoder.encode(blue, forKey: "blue")
    }
    
    public static var supportsSecureCoding: Bool {
        return true
    }
}

public class ColorTransformer: NSSecureUnarchiveFromDataTransformer {
    public override class func transformedValueClass() -> AnyClass {
        return Color.self
    }
}
