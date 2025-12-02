/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that presents the contents of a document.
*/

import UIKit
import MobileCoreServices

class DocumentViewController: UIViewController {
    
    private(set) var document: Document?
    
    var documentView: UIView {
        // This is the view that is used for the zoom transition (see DocumentBrowserViewController class).
        return particleNavigationController.view
    }
    
    // The document view controller is a compound controller.
    // It displays the particle view controller on the left and an editor view controller on the right.
    private let particleNavigationController = UINavigationController()
    private let particleViewController = ParticleViewController()
    private let editorViewController = EditorViewController()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        view.tintColor = .orange
        view.backgroundColor = #colorLiteral(red: 0.1176470588, green: 0.1176470588, blue: 0.1176470588, alpha: 1)
        
        let topInsets: CGFloat = 25.0
        let sidebarWidth: CGFloat = 300.0
        
        particleNavigationController.pushViewController(particleViewController, animated: false)
        particleNavigationController.navigationBar.barStyle = .black
        particleNavigationController.navigationBar.isTranslucent = true
        
        embed(particleNavigationController, constraintsBlock: { (subview: UIView, container: UIView) in
            return [subview.topAnchor.constraint(equalTo: container.topAnchor, constant: topInsets),
                    subview.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20.0),
                    subview.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20.0),
                    subview.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -(sidebarWidth + 20.0))]
        })
        
        let editorNavigationController = UINavigationController()
        editorNavigationController.pushViewController(editorViewController, animated: false)
        editorNavigationController.navigationBar.barStyle = .black
        editorNavigationController.navigationBar.isTranslucent = true
        embed(editorNavigationController, constraintsBlock: { (subview: UIView, container: UIView) in
            return [subview.topAnchor.constraint(equalTo: container.topAnchor, constant: topInsets),
                    subview.leadingAnchor.constraint(equalTo: particleNavigationController.view.trailingAnchor, constant: 20.0),
                    subview.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20.0),
                    subview.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20.0)]
        })
    }
    
    func embed(_ viewController: UIViewController, constraintsBlock: (UIView, UIView) -> [NSLayoutConstraint]) {
        guard let subview = viewController.view else { return }
        
        addChild(viewController)
        subview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(viewController.view)
        NSLayoutConstraint.activate(constraintsBlock(subview, view))
        viewController.didMove(toParent: self)
        
        subview.layer.cornerRadius = 8.0
        subview.layer.masksToBounds = true
        subview.clipsToBounds = true
    }
    
    func setDocument(_ document: Document, completion: @escaping () -> Void) {
        
        // Once the `DocumentViewController` is given a reference to its document, it loads its view, and opens the document.
        // This ensures that a coordinated read is performed on the document, which is necessary when dealing with documents that can be accessed by
        // multiple processes.
        self.document = document
        loadViewIfNeeded()
        
        document.open(completionHandler: { (success) in
            
            // Make sure to implement handleError(_:userInteractionPermitted:) in your UIDocument subclass to handle errors appropriately.
            if success {
                self.particleViewController.document = self.document
                self.editorViewController.document = self.document
            }
            completion()
        })
        
    }
    
    // UI Actions
    
    @IBAction func dismissDocumentViewController() {
        document?.close(completionHandler: { (_) in
            self.dismiss(animated: true)
        })
    }
}
