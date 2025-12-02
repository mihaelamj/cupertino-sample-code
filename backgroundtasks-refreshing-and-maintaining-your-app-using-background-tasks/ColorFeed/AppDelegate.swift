/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app delegate submits task requests and and registers the launch handlers for the app refresh and database cleaning background tasks.
*/

import UIKit
import BackgroundTasks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private let server: Server = MockServer()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let feedVC = (window?.rootViewController as? UINavigationController)?.viewControllers.first as? FeedTableViewController
        feedVC?.server = server
        
        PersistentContainer.shared.loadInitialData()
        
        // MARK: Registering Launch Handlers for Tasks
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.example.apple-samplecode.ColorFeed.refresh", using: nil) { task in
            // Downcast the parameter to an app refresh task as this identifier is used for a refresh request.
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.example.apple-samplecode.ColorFeed.db_cleaning", using: nil) { task in
            // Downcast the parameter to a processing task as this identifier is used for a processing request.
            self.handleDatabaseCleaning(task: task as! BGProcessingTask)
        }

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleAppRefresh()
        scheduleDatabaseCleaningIfNeeded()
    }
    
    // MARK: - Scheduling Tasks
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.example.apple-samplecode.ColorFeed.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // Fetch no earlier than 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func scheduleDatabaseCleaningIfNeeded() {
        let lastCleanDate = PersistentContainer.shared.lastCleaned ?? .distantPast

        let now = Date()
        let oneWeek = TimeInterval(7 * 24 * 60 * 60)

        // Clean the database at most once per week.
        guard now > (lastCleanDate + oneWeek) else { return }
        
        let request = BGProcessingTaskRequest(identifier: "com.example.apple-samplecode.ColorFeed.db_cleaning")
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = true
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule database cleaning: \(error)")
        }
    }
    
    // MARK: - Handling Launch for Tasks

    // Fetch the latest feed entries from server.
    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()
        
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        
        let context = PersistentContainer.shared.newBackgroundContext()
        let operations = Operations.getOperationsToFetchLatestEntries(using: context, server: server)
        let lastOperation = operations.last!
        
        task.expirationHandler = {
            // After all operations are cancelled, the completion block below is called to set the task to complete.
            queue.cancelAllOperations()
        }

        lastOperation.completionBlock = {
            task.setTaskCompleted(success: !lastOperation.isCancelled)
        }

        queue.addOperations(operations, waitUntilFinished: false)
    }
    
    // Delete feed entries older than one day.
    func handleDatabaseCleaning(task: BGProcessingTask) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        let context = PersistentContainer.shared.newBackgroundContext()
        let predicate = NSPredicate(format: "timestamp < %@", NSDate(timeIntervalSinceNow: -24 * 60 * 60))
        let cleanDatabaseOperation = DeleteFeedEntriesOperation(context: context, predicate: predicate)
        
        task.expirationHandler = {
            // After all operations are cancelled, the completion block below is called to set the task to complete.
            queue.cancelAllOperations()
        }

        cleanDatabaseOperation.completionBlock = {
            let success = !cleanDatabaseOperation.isCancelled
            if success {
                // Update the last clean date to the current time.
                PersistentContainer.shared.lastCleaned = Date()
            }
            
            task.setTaskCompleted(success: success)
        }
        
        queue.addOperation(cleanDatabaseOperation)
    }
}
