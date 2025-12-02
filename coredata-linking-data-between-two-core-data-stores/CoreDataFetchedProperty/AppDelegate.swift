/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate.
*/

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    lazy var persistentContainer: NSPersistentContainer = {

        let container = NSPersistentContainer(name: "CoreDataFetchedProperty")
        let defaultDirectoryURL = NSPersistentContainer.defaultDirectoryURL()
        
        let bookStoreURL = defaultDirectoryURL.appendingPathComponent("Books.sqlite")
        let bookStoreDescription = NSPersistentStoreDescription(url: bookStoreURL)
        bookStoreDescription.configuration = "Book"

        let feedbackStoreURL = defaultDirectoryURL.appendingPathComponent("Feedback.sqlite")
        let feedbackStoreDescription = NSPersistentStoreDescription(url: feedbackStoreURL)
        feedbackStoreDescription.configuration = "Feedback"

        container.persistentStoreDescriptions = [bookStoreDescription, feedbackStoreDescription]
        container.loadPersistentStores(completionHandler: { (_, error) in
            guard let error = error as NSError? else { return }
            fatalError("###\(#function): Failed to load persistent stores:\(error)")
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        generateSampleDataIfNeeded(context: container.newBackgroundContext())

        return container
    }()
    
    func generateSampleDataIfNeeded(context: NSManagedObjectContext) {
        context.perform {
            guard let number = try? context.count(for: Book.fetchRequest()), number == 0 else { return }
            
            let numbers = 0...9999
            for _ in 1...50 {
                let newBook = Book(context: context)
                newBook.title = "Book - " + String(format: "%04d", numbers.randomElement()!)
                newBook.uuid = UUID()
            }

            do {
                try context.save()
            } catch {
                print("Failed to save test data: \(error)")
            }
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running,
        // this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

