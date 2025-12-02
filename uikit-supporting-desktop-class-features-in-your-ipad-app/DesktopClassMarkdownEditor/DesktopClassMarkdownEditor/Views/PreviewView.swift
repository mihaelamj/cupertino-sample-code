/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for previewing document content.
*/

import UIKit
import WebKit

class PreviewView: UIView, WKNavigationDelegate {
    let webView: WKWebView

    override init(frame: CGRect) {
        let config = WKWebViewConfiguration()
        config.dataDetectorTypes = [.all]
        webView = WKWebView(frame: .zero, configuration: config)
   
        super.init(frame: frame)
  
        backgroundColor = .white
        
        webView.navigationDelegate = self
        webView.backgroundColor = .clear
        addSubview(webView)
        
        // Get read access to the app's documents directory to be able to load locally stored images.
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        webView.loadFileURL(URL(filePath: ""), allowingReadAccessTo: docsDir)
    }
    
    required init?(coder: NSCoder) {
        fatalError("called init(coder:)")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        webView.frame = bounds
    }
    
    func exportAsWebArchive(named name: String, presenter: UIViewController) {
        webView.createWebArchiveData { result in
            switch result {
            case .success(let data):
                let tempDir = FileManager.default.temporaryDirectory
                let tempUrl = tempDir.appendingPathComponent("\(name).webArchive")
                try? data.write(to: tempUrl)
                
                presenter.present(UIDocumentPickerViewController(forExporting: [tempUrl]), animated: true)
                                
            case .failure(let error):
                print("Failed to create web archive with error \(error)")
            }
        }
    }
    
    func exportAsPDF(named name: String, presenter: UIViewController) {
        webView.createPDF { result in
            switch result {
            case .success(let data):
                let tempDir = FileManager.default.temporaryDirectory
                let tempUrl = tempDir.appendingPathComponent("\(name).pdf")
                try? data.write(to: tempUrl)
                
                presenter.present(UIDocumentPickerViewController(forExporting: [tempUrl]), animated: true)

            case .failure(let error):
                print("Failed to create PDF with error \(error)")
            }
        }
    }
    
    // MARK: WKNavigationDelegate
    
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Open all links externally.
        if navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url {
            decisionHandler(.cancel)
            UIApplication.shared.open(url)
        } else {
            decisionHandler(.allow)
        }
    }

}
