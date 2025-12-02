/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Context menu example for WKWebView.
*/

import UIKit
import WebKit
import SafariServices

class WebViewBasic: UIViewController {

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

extension WebViewBasic: WKUIDelegate {
    func webView(_ webView: WKWebView,
                 contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
                 completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        let configuration =
            UIContextMenuConfiguration(identifier: nil,
                                       previewProvider: { return SFSafariViewController(url: elementInfo.linkURL!) },
                                       actionProvider: { elements in
                guard elements.isEmpty == false else { return nil }
                                        
                // Add our custom action to the existing actions passed in.
                var elementsToUse = elements
                let inspectAction = self.extraAction(elementInfo.linkURL!)
                let editMenu = UIMenu(title: "", options: .displayInline, children: [inspectAction])
                elementsToUse.append(editMenu)
                       
                let contextMenuTitle = elementInfo.linkURL?.lastPathComponent
                return UIMenu(title: contextMenuTitle!, image: nil, identifier: nil, options: [], children: elementsToUse)
            }
        )
        completionHandler(configuration)
    }
    
    /** Called when the context menu configured by the UIContextMenuConfiguration from
        webView:contextMenuConfigurationForElement:completionHandler: is committed.
        That is, when the user has selected the view provided in the UIContextMenuContentPreviewProvider.
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

extension WebViewBasic: WebViewContextMenu {

    func performExtra(_ url: URL) {
        Swift.debugPrint("Extra: \(url)")
    }

}
