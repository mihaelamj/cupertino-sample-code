/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A test case that covers the large data generator class.
*/

import Foundation
@testable import CoreDataCloudKitDemo
import XCTest
import UIKit
import CoreData
import CloudKit

class TestLargeDataGenerator: CoreDataCloudKitDemoUnitTestCase {
    var generator = LargeDataGenerator()
    var imageDatas = [Data]()
    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let resourcesURL = Bundle(for: LargeDataGenerator.self).resourceURL else {
            XCTFail("Failed to get the bundleURL for the \(type(of: LargeDataGenerator.self))")
            return
        }
        
        let resourceURLs = try FileManager.default.contentsOfDirectory(at: resourcesURL,
                                                                       includingPropertiesForKeys: nil)
        for resourceURL in resourceURLs {
            if resourceURL.lastPathComponent.hasPrefix("image") &&
                resourceURL.lastPathComponent.hasSuffix("png") {
                imageDatas.append(try Data(contentsOf: resourceURL))
            }
        }
    }
    
    override func tearDownWithError() throws {
        imageDatas.removeAll()
        try super.tearDownWithError()
    }
    
    func testGenerateData() throws {
        let context = self.coreDataStack.persistentContainer.newBackgroundContext()
        try self.generator.generateData(context: context)
        try self.verifyPosts(in: context)
    }
    
    func testExportThenImport() throws {
        let exportContainer = newContainer(role: "export", postLoadEventType: .setup)
        try self.purgeCloudData(in: exportContainer)
        let exportExpectations = expectations(for: .export, in: exportContainer)
        try self.generator.generateData(context: exportContainer.newBackgroundContext())
        self.wait(for: exportExpectations, timeout: 1200)
        
        let importContainer = newContainer(role: "import", postLoadEventType: .import)
        try self.purgeCloudData(in: importContainer)
    }
    
    func purgeCloudData(in container: NSPersistentCloudKitContainer) throws {
        let zoneID = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)
        for storeDescription in container.persistentStoreDescriptions where storeDescription.cloudKitContainerOptions?.databaseScope == .private {
            guard let store = container.persistentStoreCoordinator.persistentStore(for: storeDescription.url!) else {
                XCTFail("Failed to find store for description in container: \(container)\nDescription: \(storeDescription)")
                continue
            }
            
            let purgeExpectation = self.expectation(description: "Waiting for the purge to finish.")
            container.purgeObjectsAndRecordsInZone(with: zoneID, in: store) { purgedZoneID, purgeError in
                XCTAssertEqual(zoneID, purgedZoneID)
                XCTAssertNil(purgeError)
                purgeExpectation.fulfill()
            }
            self.waitForExpectations(timeout: 60)
        }
    }
    
    func newContainer(role: String, postLoadEventType: NSPersistentCloudKitContainer.EventType) -> NSPersistentCloudKitContainer {
        let managedObjectModel = self.coreDataStack.persistentContainer.managedObjectModel
        let container = NSPersistentCloudKitContainer(name: "\(role) Container", managedObjectModel: managedObjectModel)
        
        let privateStoreDescription = container.persistentStoreDescriptions[0]
        privateStoreDescription.url = TestAwarePersistentContainer.defaultDirectoryURL.appendingPathComponent("\(role)-store.sqlite")
        var postLoadExpectations = [XCTestExpectation]()
        container.loadPersistentStores { loadedDescription, loadError in
            XCTAssertNil(loadError)
            XCTAssertTrue(loadedDescription.url!.lastPathComponent.hasSuffix("\(role)-store.sqlite"), "Unexpected store loaded.")
            guard let store = container.persistentStoreCoordinator.persistentStore(for: loadedDescription.url!) else {
                XCTFail("Store was loaded but not returned from persistentStore(for:): \(loadedDescription)")
                return
            }

            postLoadExpectations.append(self.expectation(for: postLoadEventType,
                                                         from: store,
                                                         in: container))
        }
        
        if !postLoadExpectations.isEmpty {
            self.wait(for: postLoadExpectations, timeout: 1200)
        }
        return container
    }
    
    func expectations(for eventType: NSPersistentCloudKitContainer.EventType,
                      in container: NSPersistentCloudKitContainer) -> [XCTestExpectation] {
        var expectations = [XCTestExpectation]()
        for storeDescription in container.persistentStoreDescriptions where (storeDescription.cloudKitContainerOptions != nil) {
            guard let store = container.persistentStoreCoordinator.persistentStore(for: storeDescription.url!) else {
                XCTFail("Can't create expectations for a container that hasn't loaded yet: \(storeDescription)")
                break
            }
            expectations.append(self.expectation(for: eventType,
                                                 from: store,
                                                 in: container))
        }
        return expectations
    }
    
    func expectation(for eventType: NSPersistentCloudKitContainer.EventType,
                     from store: NSPersistentStore,
                     in container: NSPersistentCloudKitContainer) -> XCTestExpectation {
        return self.expectation(forNotification: NSPersistentCloudKitContainer.eventChangedNotification,
                                object: container) { notification in
            guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event else {
                XCTFail("Got an event-changed notification without an event: \(notification)")
                return false
            }
            
            return (event.type == eventType) &&
            (event.storeIdentifier == store.identifier) &&
            (event.endDate != nil)
        }
    }
        
    func verifyPosts(in context: NSManagedObjectContext) throws {
        try context.performAndWait {
            XCTAssertEqual(0, context.registeredObjects.count, "Context was left dirty after data generation.")
            let fetchRequest = NSFetchRequest(entityName: Attachment.entity().name!) as NSFetchRequest<NSManagedObjectID>
            fetchRequest.resultType = .managedObjectIDResultType
            let attachmentObjectIDs = try context.fetch(fetchRequest)
            for index in 0...attachmentObjectIDs.count - 1 {
                guard let attachment = context.object(with: attachmentObjectIDs[index]) as? Attachment else {
                    XCTFail("Failed to retrieve attachment \(attachmentObjectIDs[index])")
                    break
                }
                
                autoreleasepool {
                    XCTAssertNotNil(attachment.imageData)
                    let imageData = attachment.imageData!.data!
                    var foundMatch = false
                    for candidate in imageDatas where candidate == imageData {
                        foundMatch = true
                        break
                    }
                    XCTAssertTrue(foundMatch)
                    XCTAssertNil(attachment.thumbnail, "Thumbnails are transient.")
                }
                
                let post = attachment.post!
                XCTAssertFalse(post.objectID.isTemporaryID, "Posts should have been saved to the store file when generated.")
                XCTAssertEqual(11, post.attachments!.count)
                XCTAssertTrue(post.title!.hasPrefix("Post "))
                guard let wordCount = post.content?.components(separatedBy: " ").count else {
                    XCTFail("Post appears to be missing content \(post)")
                    break
                }
                XCTAssertTrue(wordCount > 2000, "This data generator should have created some longer contents for the post.")
                
                if 0 == (index % 10) {
                    context.reset()
                }
            }
        }
    }
}
