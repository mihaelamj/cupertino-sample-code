/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller for editing saved text. Allows cancellation and saving with standard bar button items, as well as with the pull-to-dismiss gesture.
*/

import UIKit

protocol EditViewControllerDelegate: AnyObject {
    
    func editViewControllerDidCancel(_ editViewController: EditViewController)
    func editViewControllerDidFinish(_ editViewController: EditViewController)
}

class EditViewController: UIViewController, UITextViewDelegate, UIAdaptivePresentationControllerDelegate {
    
    // MARK: - Model
    
    var originalText = "" {
        didSet {
            editedText = originalText
        }
    }
    
    var editedText = "" {
        didSet {
            viewIfLoaded?.setNeedsLayout()
        }
    }
    
    var hasChanges: Bool {
        return originalText != editedText
    }
    
    // MARK: - Delegate
    
    weak var delegate: EditViewControllerDelegate?
    
    // MARK: - View
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var textView: UITextView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // For user convenience, present the keyboard as soon as the app begins appearing.
        textView.becomeFirstResponder()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // Ensure textView.text is up to date.
        textView.text = editedText
        
        // If there are unsaved changes, enable the Save button and disable the ability to
        // dismiss using the pull-down gesture.
        saveButton.isEnabled = hasChanges
        isModalInPresentation = hasChanges
    }
    
    // MARK: - Events
    
    func textViewDidChange(_ textView: UITextView) {
        editedText = textView.text
    }
    
    @IBAction func cancel(_ sender: Any) {
        if hasChanges {
            // The user tapped Cancel with unsaved changes. Confirm that it's OK to lose the changes.
            confirmCancel(showingSave: false)
        } else {
            // There are no unsaved changes; ask the delegate to dismiss immediately.
            delegate?.editViewControllerDidCancel(self)
        }
    }
    
    @IBAction func save(_ sender: Any) {
        // Ask the delegate to Save any changes and dismiss this controller.
        delegate?.editViewControllerDidFinish(self)
    }
    
    // MARK: - UIAdaptivePresentationControllerDelegate
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        // The system calls this delegate method whenever the user attempts to pull
        // down to dismiss and `isModalInPresentation` is false.
        // Clarify the user's intent by asking whether they want to cancel or save.
        confirmCancel(showingSave: true)
    }

    // MARK: - Cancellation Confirmation
    
    func confirmCancel(showingSave: Bool) {
        // Present a UIAlertController as an action sheet to have the user confirm losing any
        // recent changes.
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // Only ask if the user wants to save if they attempt to pull to dismiss, not if they tap Cancel.
        if showingSave {
            alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
                self.delegate?.editViewControllerDidFinish(self)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Discard Changes", style: .destructive) { _ in
            self.delegate?.editViewControllerDidCancel(self)
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        // If presenting the alert controller as a popover, point the popover at the Cancel button.
        alert.popoverPresentationController?.barButtonItem = cancelButton
        
        present(alert, animated: true, completion: nil)
    }
}
