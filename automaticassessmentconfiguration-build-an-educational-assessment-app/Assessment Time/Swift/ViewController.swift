/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A web view.
*/

import Cocoa
import WebKit

@objc(ViewController)
class ViewController: NSViewController {
    
    @IBOutlet weak var urlField: NSTextField!
    @IBOutlet weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        webView.navigationDelegate = self
        urlField.stringValue = "https://www.apple.com"
        loadWebPage(urlField)
        
    }
    
    @IBAction func loadWebPage(_ sender: NSTextField) {
        // Make sure the url specifies the https scheme.
        if urlField.stringValue.lowercased().hasPrefix("http://") {
            urlField.stringValue = "https" + urlField.stringValue.lowercased().dropFirst("http".count)
        } else if !urlField.stringValue.lowercased().hasPrefix("https://") {
            urlField.stringValue = "https://" + urlField.stringValue
        }

        // Fail silently if a URL can't be initialized.
        guard let url = URL(string: urlField.stringValue) else { return }
        
        let request = URLRequest(url: url)
        
        webView.load(request)
    }
}

extension ViewController: WKNavigationDelegate {
    // As the user navigates from one page to another, keep the URL text field up to date.
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url else { return }
        urlField.stringValue = "\(url)"
    }
}
