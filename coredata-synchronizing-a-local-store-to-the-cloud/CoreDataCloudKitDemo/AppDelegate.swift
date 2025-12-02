/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The app delegate class of this sample.
*/

import UIKit
import CoreData
import CloudKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {
    
    var window: UIWindow?
    var locationManager: CLLocationManager = CLLocationManager()
    var locationAuthorized: Bool {
#if targetEnvironment(macCatalyst)
        return locationManager.authorizationStatus == .authorizedAlways
#else
        return locationManager.authorizationStatus == .authorizedWhenInUse
#endif //#if targetEnvironment(macCatalyst)
    }
    
    lazy var coreDataStack: CoreDataStack = { return CoreDataStack() }()

    static let sharedAppDelegate: AppDelegate = {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Check to make sure the app delegate class hasn't changed: \(String(describing: UIApplication.shared.delegate))")
        }
        return delegate
    }()
    
    // MARK: Configuration Options
    // testingEnabled - Customize class behaviors for testing. See README.md
    lazy var testingEnabled: Bool = {
        let arguments = ProcessInfo.processInfo.arguments
        var enabled = false
        for index in 0..<arguments.count - 1 where arguments[index] == "-CDCKDTesting" {
            enabled = arguments.count >= (index + 1) ? arguments[index + 1] == "1" : false
            break
        }
        return enabled
    }()
    
    // allowCloudKitSync - Enable or disable CloudKit sync. See README.md
    lazy var allowCloudKitSync: Bool = {
        let arguments = ProcessInfo.processInfo.arguments
        var allow = true
        for index in 0..<arguments.count - 1 where arguments[index] == "-CDCKDAllowCloudKitSync" {
            allow = arguments.count >= (index + 1) ? arguments[index + 1] == "1" : true
            break
        }
        return allow
    }()
    
    // MARK: Sharing Support
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // The main storyboard defines the view controller hierarchy.
        guard let splitViewController = window?.rootViewController as? UISplitViewController,
            let navController = splitViewController.viewControllers[splitViewController.viewControllers.count - 1] as? UINavigationController,
            let topViewController = navController.topViewController else {
                return false
        }
        // Configure the splitViewController.
        topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .oneBesideSecondary
        return true
    }

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        // Clear any selection because the controller is about to collapse.
        if let navController = splitViewController.viewControllers[0] as? UINavigationController,
            let mainViewController = navController.viewControllers[0] as? MainViewController,
            let selectedRow = mainViewController.tableView.indexPathForSelectedRow {
            mainViewController.tableView.deselectRow(at: selectedRow, animated: true)
        }
        return true // Return true to always show the main view.
    }
    
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        let sharedStore = AppDelegate.sharedAppDelegate.coreDataStack.sharedPersistentStore
        let container = AppDelegate.sharedAppDelegate.coreDataStack.persistentContainer
        container.acceptShareInvitations(from: [cloudKitShareMetadata], into: sharedStore, completion: nil)
    }
}
