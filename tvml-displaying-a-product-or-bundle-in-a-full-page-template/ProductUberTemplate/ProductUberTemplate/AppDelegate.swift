/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application delegate class that starts TVML and handles callbacks
*/
import UIKit
import TVMLKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var appController: TVApplicationController?
    
    static let TVBootURL = "http://localhost:9001/js/application.js"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)

        let appControllerContext = TVApplicationControllerContext()
        guard let javaScriptURL = URL(string: AppDelegate.TVBootURL) else { fatalError("unable to create URL") }
        appControllerContext.javaScriptApplicationURL = javaScriptURL

        appController = TVApplicationController(context: appControllerContext, window: window, delegate: self)
        
        return true
    }
}

// MARK: Document Service

extension AppDelegate: TVApplicationControllerDelegate {
    func appController(_ appController: TVApplicationController, didFinishLaunching options: [String: Any]?) {
        // Specify the context for the initial document request.
        let contextDictionary = ["url": "templates/Index.xml"]
        
        // Create the document controller using the context.
        let documentController = TVDocumentViewController(context: contextDictionary, for: appController)
        documentController.delegate = self
        
        // Push it onto the navigation stack to start the loading of the document.
        appController.navigationController.pushViewController(documentController, animated: false)
    }
}

extension AppDelegate: TVDocumentViewControllerDelegate {
    func documentViewController(_ documentViewController: TVDocumentViewController,
                                handleEvent event: TVDocumentViewController.Event, with element: TVViewElement) -> Bool {

        // Handle events that come from within the document view controllers or defer to
        // Javascript by not handling it and returning false.

        guard element.elementData["url"] != nil, let appController = appController else {
            return false
        }
        
        var handled = false
        if event == .select {
            var useBrowser = false
            
            if let attributes = element.attributes {
                if let useBrowserString = attributes["useBrowser"] {
                    useBrowser = useBrowserString == "true"
                }
            }
            
            // Select events that lead to a document being loaded in a browser is handled
            // in JavaScript.
            if useBrowser == false {
                let documentController = TVDocumentViewController(context: element.elementData, for: appController)
                documentController.delegate = self
                appController.navigationController.pushViewController(documentController, animated: true)
                handled = true
            }
        }
        
        return handled
    }
}
