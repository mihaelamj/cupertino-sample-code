/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
ViewController that shows documents, allows to edit them and to ask questions about them.
*/

import UIKit
import CoreML

class DetailViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {

    @IBOutlet weak var questionTextField: UITextField!
    @IBOutlet weak var documentTextView: UITextView!
    @IBOutlet weak var questionTextFieldBottomLayoutConstraint: NSLayoutConstraint!
    
    let bert = BERT()

    func configureView() {
        guard let detail = detailItem else {
            return
        }
        
        title = detail.title

        guard let textView = documentTextView else {
            return
        }
        
        let fullTextColor = UIColor(named: "Full Text Color")!
        let helveticaNeue17 = UIFont(name: "HelveticaNeue", size: 17)!
        let bodyFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: helveticaNeue17)
        
        let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: fullTextColor,
                                                         .font: bodyFont]
        
        textView.attributedText = NSAttributedString(string: detail.body,
                                                             attributes: attributes)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    var detailItem: Document? {
        didSet {
            configureView()
        }
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // The user pressed the `Search` button.
        guard let detail = detailItem else {
            return false
        }
        
        // Update UI to indicate the app is searching for an answer.
        let searchText = textField.text ?? ""
        let placeholder = textField.placeholder
        textField.placeholder = "Searching..."
        textField.text = ""

        // Run the search in the background to keep the UI responsive.
        DispatchQueue.global(qos: .userInitiated).async {
            // Use the BERT model to search for the answer.
            let answer = self.bert.findAnswer(for: searchText, in: detail.body)

            // Update the UI on the main queue.
            DispatchQueue.main.async {
                if answer.base == detail.body, let textView = self.documentTextView {
                    // Highlight the answer substring in the original text.
                    let semiTextColor = UIColor(named: "Semi Text Color")!
                    let helveticaNeue17 = UIFont(name: "HelveticaNeue", size: 17)!
                    let bodyFont = UIFontMetrics(forTextStyle: .body).scaledFont(for: helveticaNeue17)
                    
                    let mutableAttributedText = NSMutableAttributedString(string: detail.body,
                                                                          attributes: [.foregroundColor: semiTextColor,
                                                                                       .font: bodyFont])
                    
                    let location = answer.startIndex.utf16Offset(in: detail.body)
                    let length = answer.endIndex.utf16Offset(in: detail.body) - location
                    let answerRange = NSRange(location: location, length: length)
                    let fullTextColor = UIColor(named: "Full Text Color")!
                    
                    mutableAttributedText.addAttributes([.foregroundColor: fullTextColor],
                                                         range: answerRange)
                    textView.attributedText = mutableAttributedText
                }
                textField.text = String(answer)
                textField.placeholder = placeholder
            }
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        configureView()
        return true
    }

    // MARK: - UITextViewDelegate

    func textViewDidEndEditing(_ textView: UITextView) {
        detailItem = Document(title: detailItem?.title ?? "New Document", body: textView.text)
    }
    
    // MARK: - Keyboard Event Handling
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIWindow.keyboardWillShowNotification,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: UIWindow.keyboardWillHideNotification,
                                               object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIWindow.keyboardWillShowNotification,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: UIWindow.keyboardWillHideNotification,
                                                  object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        questionTextField.becomeFirstResponder()
    }
    
    @objc
    func keyboardWillShow(notification: NSNotification) {
        animateBottomLayoutConstraint(from: notification)
    }
    
    @objc
    func keyboardWillHide(notification: NSNotification) {
        animateBottomLayoutConstraint(from: notification)
    }
    
    func animateBottomLayoutConstraint(from notification: NSNotification) {
        guard let userInfo = notification.userInfo else {
            print("Unable to extract: User Info")
            return
        }

        guard let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
            print("Unable to extract: Animation Duration")
            return
        }
        
        guard let keyboardEndFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            print("Unable to extract: Keyboard Frame End")
            return
        }
        
        guard let keyboardBeginFrame = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue else {
            print("Unable to extract: Keyboard Frame Begin")
            return
        }
        
        guard let rawAnimationCurve = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue else {
            print("Unable to extract: Keyboard Animation Curve")
            return
        }
        
        let offset = keyboardEndFrame.minY - keyboardBeginFrame.minY
        questionTextFieldBottomLayoutConstraint.constant -= offset
        
        let curveOption = UIView.AnimationOptions(rawValue: rawAnimationCurve << 16)

        UIView.animate(withDuration: animationDuration,
                       delay: 0.0,
                       options: [.beginFromCurrentState, curveOption],
                       animations: { self.view.layoutIfNeeded() },
                       completion: nil)
    }
}
