/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
UIViewController subclass that contains the content for the comment popover.
*/

import UIKit

class CommentPopoverViewController: UIViewController, UITextFieldDelegate {
   
    private var selectedReaction: Reaction = .thumbsUp
    
    var viewController: TextDocumentViewController! = nil
    
    @IBOutlet private var commentField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        overrideUserInterfaceStyle = .light
        commentField.delegate = self
        commentField.becomeFirstResponder()
        
        // This is called when a reaction button needs an update.
        let buttonUpdateHandler: (UIButton) -> Void = { button in
            button.configuration?.baseBackgroundColor =
                button.isSelected ? UIColor.systemIndigo : UIColor.gray
        }
        
        // Add a configuration update handler to each reaction button.
        for reaction in Reaction.allCases {
            if let button = buttonForReaction(reaction) {
                button.configurationUpdateHandler = buttonUpdateHandler
            }
        }
        
        if let selectedReactionButton = buttonForReaction(selectedReaction) {
            selectedReactionButton.isSelected = true
        }
    }
    
    private let reactionAttachmentColor = UIColor.systemYellow
    
    private func imageForAttachment(with reaction: Reaction) -> UIImage {
        let reactionConfig = UIImage.SymbolConfiguration(textStyle: .title3, scale: .large)
        var symbolImageForReaction = UIImage(systemName: reaction.symbolName, withConfiguration: reactionConfig)
        symbolImageForReaction = symbolImageForReaction!.withRenderingMode(.alwaysTemplate)
        return symbolImageForReaction!
    }
    
    func attributedString(for reaction: Reaction) -> NSAttributedString {
        let reactionAttachment = NSTextAttachment()
        reactionAttachment.image = imageForAttachment(with: reaction)
        let reactionAttachmentString = NSMutableAttributedString(attachment: reactionAttachment)
        // Add the foreground color attribute so the symbol icon renders with the reactionAttachmentColor (yellow).
        reactionAttachmentString.addAttribute(.foregroundColor,
                                              value: reactionAttachmentColor,
                                              range: NSRange(location: 0, length: reactionAttachmentString.length))
        return reactionAttachmentString
    }
    
    // Creating the comment.
    func attributedComment(_ comment: String, with reaction: Reaction) -> NSAttributedString {
        let reactionAttachmentString = attributedString(for: reaction)
        let commentWithReaction = NSMutableAttributedString(string: comment + " ")
        commentWithReaction.append(reactionAttachmentString)
        return commentWithReaction
    }

    @IBAction func reactionChanged(_ sender: UIButton) {
        let newReaction = Reaction(rawValue: sender.tag)
        let oldReaction = selectedReaction

        let newReactionButton = sender
        
        if newReaction != oldReaction {
            newReactionButton.isSelected = true
            
            if let oldReactionButton = buttonForReaction(oldReaction) {
                // Toggle the old reaction button state.
                oldReactionButton.isSelected = false
            }
            selectedReaction = newReaction!
         } else {
             // User toggled the current reaction button to off.
             selectedReaction = .none
         }
    }
    
    func buttonForReaction(_ reaction: Reaction) -> UIButton? {
        if let button = view.viewWithTag(reaction.rawValue) as? UIButton {
            return button
        } else {
            return nil
        }
    }
    
    var selectedReactionButtonColor: UIColor {
        return UIColor.systemIndigo
    }
    var unselectedReactionButtonColor: UIColor {
        return UIColor.systemGray
    }
    
    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !textField.text!.isEmpty && selectedReaction != .none {
            textField.resignFirstResponder()
            dismiss(animated: true, completion: { [self] in
                let attributedCommentWithReaction = attributedComment(textField.text!, with: selectedReaction)
                viewController.addComment(comment: attributedCommentWithReaction)
        })
            return true
        } else {
            return false
        }
    }

}
