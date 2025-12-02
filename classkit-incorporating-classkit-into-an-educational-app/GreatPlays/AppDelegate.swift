/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate.
*/

import UIKit
import ClassKit
import os

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    /// Entry point.
    /// - Tag: addHamlet
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        if let splitViewController = window?.rootViewController as? UISplitViewController,
            let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count - 1] as? UINavigationController {
            
            navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            splitViewController.delegate = self
        }

        // Initialize the one built-in play.
        PlayLibrary.shared.addPlay(PlayLibrary.hamlet)
        
        return true
    }

    /// Handles a continuation activity.
    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.isClassKitDeepLink,
            let identifierPath = userActivity.contextIdentifierPath {
            
            // The first element of the identifier path is the main app context, which we don't need, so drop it.
            return navigate(to: Array(identifierPath.dropFirst()))
        }
        
        return false
    }
    
    /// Handles a URL scheme that we've registered in Info.plist.
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        
        // Handle URLs with the `greatplays` scheme, and composed of node identifiers:
        //  greatplays://play/act/scene/quiz
        os_log("%s", url.absoluteString)
        if let host = url.host?.removingPercentEncoding, url.scheme == "greatplays" {
            return navigate(to: [host] + Array(url.pathComponents.dropFirst().map({ $0.removingPercentEncoding ?? "" })))
        }
        
        return false
    }
    
    /// Navigates in the UI to the area of the app corresponding to the given identifier path.
    func navigate(to identifierPath: [String]) -> Bool {
        guard let identifier = identifierPath.first,
            let play = PlayLibrary.shared.plays.first(where: { $0.identifier == identifier }),
            let node = play.descendant(matching: Array(identifierPath.suffix(identifierPath.count - 1))) else {
            return false
        }
        
        switch node {
        case let play as Play:
            navigate(to: play)
        case let act as Act:
            navigate(to: act)
        case let scene as Scene:
            navigate(to: scene)
        case let quiz as Quiz:
            navigate(to: quiz)
        default:
            return false
        }
        
        return true
    }
    
    /// Navigates to the given play.
    private func navigate(to play: Play) {
        guard let splitViewController = window?.rootViewController as? UISplitViewController,
            let masterNav = splitViewController.viewControllers.first as? UINavigationController,
            let detailNav = splitViewController.viewControllers.last as? UINavigationController,
            let playList = masterNav.viewControllers.first as? PlaysTableViewController else {
                return
        }
        
        // Dismiss any quiz that happens to be present.
        detailNav.dismiss(animated: false)
        
        if let row = playList.plays.firstIndex(where: { $0.identifier == play.identifier }) {
            playList.tableView.selectRow(at: IndexPath(row: row, section: 0), animated: false, scrollPosition: .top)
        }
        
        detailNav.popToRootViewController(animated: false)
    }

    /// Navigates to the given act.
    private func navigate(to act: Act) {
        navigate(to: act.play)
        
        guard let splitViewController = window?.rootViewController as? UISplitViewController,
            let detailNav = splitViewController.viewControllers.last as? UINavigationController,
            let actsTable = detailNav.viewControllers.last as? ActsTableViewController,
            let storyboard = actsTable.storyboard,
            let scenesTable = storyboard.instantiateViewController(withIdentifier: "ScenesTableViewController") as? ScenesTableViewController else {
                return
        }

        actsTable.play = act.play
        scenesTable.act = act
        
        detailNav.pushViewController(scenesTable, animated: false)
    }
    
    /// Navigates to the given scene.
    private func navigate(to scene: Scene) {
        navigate(to: scene.act)
        
        guard let splitViewController = window?.rootViewController as? UISplitViewController,
            let detailNav = splitViewController.viewControllers.last as? UINavigationController,
            let scenesTable = detailNav.viewControllers.last as? ScenesTableViewController,
            let storyboard = scenesTable.storyboard,
            let sceneView = storyboard.instantiateViewController(withIdentifier: "SceneViewController") as? SceneViewController else {
                return
        }
        
        sceneView.scene = scene
        detailNav.pushViewController(sceneView, animated: false)
    }
        
    /// Navigates to the given quiz.
    private func navigate(to quiz: Quiz) {
        navigate(to: quiz.scene)
        
        guard let splitViewController = window?.rootViewController as? UISplitViewController,
            let detailNav = splitViewController.viewControllers.last as? UINavigationController,
            let sceneView = detailNav.viewControllers.last as? SceneViewController else {
                return
        }
        
        sceneView.presentQuiz(quiz)
    }
}

extension AppDelegate: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController,
                             collapseSecondary secondaryViewController: UIViewController,
                             onto primaryViewController: UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? ActsTableViewController else { return false }
        if topAsDetailController.play == nil {
            return true
        }
        return false
    }
}
