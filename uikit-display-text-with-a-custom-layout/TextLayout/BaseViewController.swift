/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller class that handles keyboard notifications.
*/

import UIKit
import Combine

class BaseViewController: UIViewController {
    
    private var keyboardSubscriptions: AnyCancellable?

    // Use @objc so subclasses can KVO textView's properties like contentOffset.
    //
    @objc var textView: UITextView!

    lazy var textStorage: NSTextStorage = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        return appDelegate!.textStorage
    }()

    // Subscribe the keyboard notifications when the view is about to appear.
    //
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let publishers = [UIResponder.keyboardWillShowNotification,
                          UIResponder.keyboardWillHideNotification].map {
            NotificationCenter.default.publisher(for: $0)
        }

        // Set up the keyboard notification handler.
        // Adjust scrollView.contentInset.bottom according to the keyboard height.
        //
        keyboardSubscriptions = Publishers.MergeMany(publishers).sink { notification in
            var newContentInset = UIEdgeInsets.zero
            if notification.name == UIResponder.keyboardWillShowNotification,
                let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                let keybardHeight = frame.cgRectValue.size.height
                newContentInset = UIEdgeInsets(top: 0, left: 0, bottom: keybardHeight, right: 0)
            }
            self.textView.contentInset = newContentInset
        }
    }

    // Cancel the subscription after the view disappears.
    //
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        keyboardSubscriptions?.cancel()
    }
}
