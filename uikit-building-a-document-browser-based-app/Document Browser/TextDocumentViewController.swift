/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller for displaying and editing documents.
*/

import UIKit
import os.log

/// - Tag: textDocumentViewController
class TextDocumentViewController: UIViewController, UITextViewDelegate, TextDocumentDelegate {

    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var doneButton: UIBarButtonItem!

    private var keyboardAppearObserver: Any?
    private var keyboardDisappearObserver: Any?
    
    var document: TextDocument! {
        didSet {
            document.delegate = self
            loadViewIfNeeded()
        }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setupNotifications()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNotifications()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.delegate = self
        doneButton.isEnabled = false
        
        if #available(iOS 13.0, *) {
            /** When turned on, this changes the rendering scale of the text to match the standard text scaling
                and preserves the original font point sizes when the contents of the text view are copied to the pasteboard.
                Apps that show a lot of text content, such as a text viewer or editor, should turn this on and use the standard text scaling.
             
                For more information, refer to the WWDC 2019 video on session 227 "Font Management and Text Scaling"
                    https://developer.apple.com/videos/play/wwdc2019/227/
                        (from around 30 minutes in, and to the end)
            */
            textView.usesStandardTextScaling = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
                
        assert(!document.documentState.contains(.closed), "*** Open the document before displaying it. ***")
        
        assert(!document.documentState.contains(.inConflict), "*** Resolve conflicts before displaying the document. ***")

        textView.text = document.text
        
        // Set the view controller's title to match file document's title.
        let fileAttributes = try? document.fileURL.resourceValues(forKeys: [URLResourceKey.localizedNameKey])
        navigationItem.title = fileAttributes?.localizedName
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        document.close { (success) in
            guard success else { fatalError( "*** Error closing document ***") }
            
            os_log("==> Document saved and closed", log: .default, type: .debug)
        }
    }
    
    // MARK: - Action Methods
    
    @IBAction func editingDone(_ sender: Any) {
        textView.resignFirstResponder()
    }
    
    @IBAction func returnToDocuments(_ sender: Any) {
        // Dismiss this view controller.
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.25) {
            self.doneButton.isEnabled = true
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        document.text = textView.text
        document.updateChangeCount(.done)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        UIView.animate(withDuration: 0.25) {
            self.doneButton.isEnabled = false
        }

        document.text = textView.text
        document.updateChangeCount(.done)
    }
    
    // MARK: - UITextDocumentDelegate Methods
    
    func textDocumentEnableEditing(_ doc: TextDocument) {
        textView.isEditable = true
    }
    
    func textDocumentDisableEditing(_ doc: TextDocument) {
        textView.isEditable = false
    }
    
    func textDocumentUpdateContent(_ doc: TextDocument) {
        textView.text = doc.text
    }
    
    func textDocumentTransferBegan(_ doc: TextDocument) {
        progressBar.isHidden = false
        progressBar.observedProgress = doc.progress
    }
    
    func textDocumentTransferEnded(_ doc: TextDocument) {
        progressBar.isHidden = true
    }
    
    func textDocumentSaveFailed(_ doc: TextDocument) {
        let alert = UIAlertController(
            title: NSLocalizedString("SaveErrorTitle", comment: ""),
            message: NSLocalizedString("SaveErrorTitleMessage", comment: ""),
            preferredStyle: .alert)
        
        let dismiss = UIAlertAction(title: NSLocalizedString("OKTitle", comment: ""), style: .default)
        alert.addAction(dismiss)
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Private Methods
    
    private func setupNotifications() {
        let notificationCenter = NotificationCenter.default
        
        keyboardAppearObserver = notificationCenter.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: nil) { (notification) in
                self.adjustForKeyboard(notification: notification)
        }
        
        keyboardDisappearObserver = notificationCenter.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: nil) { (notification) in
                self.adjustForKeyboard(notification: notification)
        }
    }
    
    @objc
    func adjustForKeyboard(notification: Notification) {
        let userInfo = notification.userInfo

        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardFrame.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            textView.contentInset = .zero
        } else {
            textView.contentInset = UIEdgeInsets(top: 0,
                                                 left: 0,
                                                 bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom,
                                                 right: 0)
        }

        textView.scrollIndicatorInsets = textView.contentInset

        guard let animationDuration =
            userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
                 as? Double else {
                     fatalError("*** Unable to get the animation duration ***")
         }
         
         guard let curveInt =
            userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int else {
                 fatalError("*** Unable to get the animation curve ***")
         }
         
         guard let animationCurve =
             UIView.AnimationCurve(rawValue: curveInt) else {
                 fatalError("*** Unable to parse the animation curve ***")
         }

         UIViewPropertyAnimator(duration: animationDuration, curve: animationCurve) {
             self.view.layoutIfNeeded()
            
            let selectedRange = self.textView.selectedRange
            self.textView.scrollRangeToVisible(selectedRange)
            
         }.startAnimation()
    }
    
}
