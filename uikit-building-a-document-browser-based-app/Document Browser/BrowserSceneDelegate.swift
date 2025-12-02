/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The scene delegate for the main browser for this application.
*/

import UIKit
import os.log

@available(iOS 13.0, *)
class BrowserSceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    // The session userInfo key (for marking this scene delegate session as the document browser).
    static let documentBrowserIdentifierKey = "browser"
    
    var window: UIWindow?

    class func browserSceneSession() -> UISceneSession? {
        var browserSceneSession: UISceneSession!
        for session in UIApplication.shared.openSessions {
            if session.userInfo![BrowserSceneDelegate.documentBrowserIdentifierKey] != nil {
                browserSceneSession = session
                break
            }
        }
        return browserSceneSession
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Mark this session's userInfo as the main document browser so you can find it among multiple sessions.
        session.userInfo = [BrowserSceneDelegate.documentBrowserIdentifierKey: "main browser"]

        if let urlContext = connectionOptions.urlContexts.first {
            openURLContext(urlContext)
        }
    }
    
    // You are being asked to open a document (via Files App -> Share).
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Only open the first document you are passed.
        if let urlContext = URLContexts.first {
            openURLContext(urlContext)
        }
    }

    private func openURLContext(_ urlContext: UIOpenURLContext) {
        // Reveal and import the document at the URL.
        guard let documentBrowserViewController = window?.rootViewController as? DocumentBrowserViewController else {
            fatalError("*** The root view is not a document browser ***")
        }

        let inputURL = urlContext.url
        let canOpenInPlace = urlContext.options.openInPlace
        documentBrowserViewController.revealDocument(at: inputURL, importIfNeeded: !canOpenInPlace) { (revealedDocumentURL, error) in

            // Note that this app supports both open in place and open a copy (if urlContext.options.openInPlace is false, revealedDocumentURL is nil)

            Swift.debugPrint("\(canOpenInPlace)")

            let urlToOpen: URL

            if canOpenInPlace {
                urlToOpen = inputURL
            } else {
                guard let revealedDocumentURL = revealedDocumentURL else {
                    os_log("*** Failed to reveal the document at %@. Error: %@. ***",
                           log: .default,
                           type: .error,
                           inputURL as CVarArg,
                           error as CVarArg? ?? "nil")
                    return
                }

                urlToOpen = revealedDocumentURL
            }

            // Present the Document View Controller for the revealed URL.
            documentBrowserViewController.presentDocument(at: urlToOpen)
        }
    }
    
}
