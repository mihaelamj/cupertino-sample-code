/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This test case covers the Core Data stack and verifies the app can write values for all of its model objects.
*/

import XCTest
import CoreData
@testable import CoreDataCloudKitDemo

extension TestCoreDataStack {
    func testAllValuesAreWriteable() throws {
        let context = coreDataStack.persistentContainer.newBackgroundContext()
        try context.performAndWait {
            var cache = [String: NSManagedObject]()
            for (entityName, entity) in coreDataStack.persistentContainer.managedObjectModel.entitiesByName {
                let object = try generateObject(for: entity, in: context, cache: &cache)
                XCTAssertNoThrow(try context.save(), "Failed to save generated object graph for entity: \(entityName)\n\(object)")
            }
        }
    }
    
    // MARK: Generating Sample Data
    func generateObject(for entity: NSEntityDescription,
                        in context: NSManagedObjectContext,
                        cache: inout [String: NSManagedObject],
                        populateRelationships: Bool = true) throws -> NSManagedObject {
        if let object = cache[entity.name!] {
            return object
        }
        
        let object = NSEntityDescription.insertNewObject(forEntityName: entity.name!, into: context)
        try self.populateAttributes(on: object)
        if populateRelationships {
            try self.populateRelationships(on: object, cache: &cache)
        }
        
        return object
    }
    
    func populateAttributes(on object: NSManagedObject) throws {
        for (attributeName, attribute) in object.entity.attributesByName {
            object.setValue(try generateValue(for: attribute), forKey: attributeName)
        }
    }
    
    func populateRelationships(on object: NSManagedObject,
                               cache: inout [String: NSManagedObject]) throws {
        for (_, relationship) in object.entity.relationshipsByName {
            try generateRelatedObjects(for: relationship,
                                          on: object,
                                          cache: &cache)
        }
    }
    
    func generateValue(for attribute: NSAttributeDescription) throws -> Any {
        switch attribute.type {
        case .date:
            return Date()
        case .string:
            return "An example core data string"
        case .boolean:
            return NSNumber(true)
        case .double, .float, .decimal:
            return NSNumber(10.52)
        case .integer16, .integer32, .integer64:
            return NSNumber(65_536)
        case .binaryData:
            return "Some example data".data(using: .utf8)!
        case .transformable:
            return try self.generateTransformableValue(for: attribute)
        case .uuid:
            return NSUUID()
        case .uri:
            return NSURL(string: "http://www.apple.com")!
        default:
            fatalError("Unexpected attribute type, please add support to this method to generate a value for \(attribute)")
        }
    }
    
    func generateTransformableValue(for transformableAttribute: NSAttributeDescription) throws -> Any {
        guard let attribute = (transformableAttribute.type == .transformable) ? transformableAttribute : nil else {
            fatalError("This method only knows how to create values for transformable attributes: \(transformableAttribute)")
        }
        
        if attribute.attributeValueClassName == "UIKit.UIImage" {
            return UIImage(systemName: "person.icloud")!
        } else if attribute.attributeValueClassName == "CoreLocation.CLLocation" {
            return AppDelegate.sharedAppDelegate.locationManager.location!
        } else if attribute.attributeValueClassName == "UIKit.UIColor" {
            return UIColor.blue
        } else {
            fatalError("Unsupported transformable attribute. Please add support to this method to generate a value for \(attribute)")
        }
    }
    
    func generateRelatedObjects(for relationship: NSRelationshipDescription,
                                on object: NSManagedObject,
                                cache: inout [String: NSManagedObject]) throws {
        if relationship.isToMany {
            guard let value = object.value(forKey: relationship.name) as? Set<NSManagedObject> else {
                fatalError("Unexpected relationship value for '\(relationship.name)' on \(object)")
            }
            
            if value.isEmpty {
                let member = try self.generateObject(for: relationship.destinationEntity!,
                                                        in: object.managedObjectContext!,
                                                        cache: &cache,
                                                        populateRelationships: false)
                object.setValue(NSMutableSet(objects: member), forKey: relationship.name)
            }
        } else if relationship.inverseRelationship!.isToMany {
            if nil == object.value(forKey: relationship.name) {
                object.setValue(try self.generateObject(for: relationship.destinationEntity!,
                                                           in: object.managedObjectContext!,
                                                           cache: &cache,
                                                           populateRelationships: false),
                                forKey: relationship.name)
            }
        } else {
            if nil == object.value(forKey: relationship.name) {
                let relatedObject = try self.generateObject(for: relationship.destinationEntity!,
                                                               in: object.managedObjectContext!,
                                                               cache: &cache,
                                                               populateRelationships: false)
                object.setValue(relatedObject, forKey: relationship.name)
                try self.populateRelationships(on: relatedObject,
                                               cache: &cache)
                
            }
        }
    }
}
