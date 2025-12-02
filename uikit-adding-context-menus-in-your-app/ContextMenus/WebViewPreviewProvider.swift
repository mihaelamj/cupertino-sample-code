/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Context menu example with preview provider for WKWebView.
*/

import UIKit
import WebKit
import SafariServices

class WebViewPreviewProvider: UIViewController {

    @IBOutlet var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pathURL = Bundle.main.url(forResource: "content", withExtension: "html")
        do {
            webView.uiDelegate = self // for contextMenuConfigurationForElement
            
            let contentStr = try String(contentsOfFile: pathURL!.path)
            webView.loadHTMLString(contentStr, baseURL: nil)
        } catch {
            // Failed to load local content.html.
        }
    }

}

extension WebViewPreviewProvider: WKUIDelegate {
    
    /** Called when a context menu interaction begins.
        Pass a valid UIContextMenuConfiguration to show a context menu, or pass nil in the completion handler to not show a context menu.
        Use the linkURL property on the provided WKContextMenuElementInfo object to get the link, and then call the completion handler
        with a custom UIContextMenuConfiguration.
    */
    func webView(_ webView: WKWebView,
                 contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
                 completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        guard let url = elementInfo.linkURL else { return completionHandler(nil) }

        let configuration =
            UIContextMenuConfiguration(identifier: nil,
                previewProvider: {
                    // Here we use our own custom preview provider.
                    if let previewViewController =
                            self.storyboard?.instantiateViewController(
                                identifier: "URLPreviewViewController") as? URLPreviewViewController {
                        previewViewController.url = url
                        return previewViewController
                    } else {
                        // Couldn't find the preview view controller, so fallback to SFSafariViewController.
                        return SFSafariViewController(url: url)
                    }
                },
                actionProvider: { elements in
                    guard elements.isEmpty == false else { return nil }
                    
                    // Add our custom action to the existing actions passed in.
                    var elementsToUse = elements
                    let inspectAction = self.extraAction(elementInfo.linkURL!)
                    let editMenu = UIMenu(title: "", options: .displayInline, children: [inspectAction])
                    elementsToUse.append(editMenu)

                    return UIMenu(title: "", image: nil, identifier: nil, options: [], children: elementsToUse)
                })
        completionHandler(configuration)
    }

    /** Called when the context menu configured by the UIContextMenuConfiguration from
        webView:contextMenuConfigurationForElement:completionHandler: is committed.
        That is, when the user has selected the view provided in the UIContextMenuContentPreviewProvider.
        Present the view controller as part of a completion for the animator.
     */
    func webView(_ webView: WKWebView,
                 contextMenuForElement elementInfo: WKContextMenuElementInfo,
                 willCommitWithAnimator animator: UIContextMenuInteractionCommitAnimating) {
        animator.addCompletion {
            // User tapped somewhere in view controller preview, so modally present SFSafariViewController.
            let safariViewController = SFSafariViewController(url: elementInfo.linkURL!)
            self.present(safariViewController, animated: true)
        }
    }
    
    func webView(_ webView: WKWebView, contextMenuWillPresentForElement elementInfo: WKContextMenuElementInfo) {
        //Swift.debugPrint("contextMenuWillPresentForElement: \(String(describing: elementInfo.linkURL?.host)))")
    }
    
    func webView(_ webView: WKWebView, contextMenuDidEndForElement elementInfo: WKContextMenuElementInfo) {
        //Swift.debugPrint("contextMenuDidEndForElement: \(String(describing: elementInfo.linkURL?.host)))")
    }
    
}

// MARK: - WebViewContextMenu

extension WebViewPreviewProvider: WebViewContextMenu {

    func performExtra(_ url: URL) {
        Swift.debugPrint("Extra: \(url)")
    }

}
