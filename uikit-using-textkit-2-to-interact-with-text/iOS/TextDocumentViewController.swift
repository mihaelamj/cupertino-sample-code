/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The application's primary view controller.
*/

import UIKit

class TextDocumentViewController: UIViewController,
                                  NSTextContentManagerDelegate,
                                  NSTextContentStorageDelegate,
                                  UIPopoverPresentationControllerDelegate {

    private var textContentStorage: NSTextContentStorage
    private var textLayoutManager: NSTextLayoutManager
    private var fragmentForCurrentComment: NSTextLayoutFragment?
    private var showComments = true
    var commentColor: UIColor { return .white }
    
    @IBOutlet var toggleComments: UIButton!

    var textDocumentView: TextDocumentView {
        get {
            return (view as? TextDocumentView)!
        }
    }

    required init?(coder: NSCoder) {
        textLayoutManager = NSTextLayoutManager()
        textContentStorage = NSTextContentStorage()
        super.init(coder: coder)
        textContentStorage.delegate = self
        textContentStorage.addTextLayoutManager(textLayoutManager)
        let textContainer = NSTextContainer(size: CGSize(width: 200, height: 0))
        textLayoutManager.textContainer = textContainer
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let docURL = Bundle.main.url(forResource: "menu", withExtension: "rtf") {
            do {
                try textContentStorage.textStorage?.read(from: docURL, documentAttributes: nil)
            } catch {
                // Could not read menu content.
            }
        }
        
        // This is called when the toggle comment button needs an update.
        let toggleUpdateHandler: (UIButton) -> Void = { [self] button in
            button.configuration?.image =
                button.isSelected ? UIImage(systemName: "text.bubble.fill") : UIImage(systemName: "text.bubble")
            self.showComments = button.isSelected
            textDocumentView.layer.setNeedsLayout()
        }
        toggleComments.configurationUpdateHandler = toggleUpdateHandler

        textDocumentView.textContentStorage = textContentStorage
        textDocumentView.textLayoutManager = textLayoutManager
        textDocumentView.updateContentSizeIfNeeded()
        textDocumentView.viewController = self
    }
    
    // Commenting
    
    var commentFont: UIFont {
        var commentFont = UIFont.preferredFont(forTextStyle: .title3)
        let commentFontDescriptor = commentFont.fontDescriptor.withSymbolicTraits(.traitItalic)
        commentFont = UIFont(descriptor: commentFontDescriptor!, size: commentFont.pointSize)
        return commentFont
    }
    
    func addComment(comment: NSAttributedString) {
        textDocumentView.addComment(comment, below: fragmentForCurrentComment!)
        fragmentForCurrentComment = nil
    }
    
    // MARK: - NSTextContentManagerDelegate
    
    func textContentManager(_ textContentManager: NSTextContentManager,
                            shouldEnumerate textElement: NSTextElement,
                            options: NSTextContentManager.EnumerationOptions) -> Bool {
        // The text content manager calls this method to determine whether each text element should be enumerated for layout.
        // To hide comments, tell the text content manager not to enumerate this element if it's a comment.
        if !showComments {
            if let paragraph = textElement as? NSTextParagraph {
                let commentDepthValue = paragraph.attributedString.attribute(.commentDepth, at: 0, effectiveRange: nil)
                if commentDepthValue != nil {
                    return false
                }
            }
        }
        return true
    }
    
    // MARK: - NSTextContentStorageDelegate
    
    func textContentStorage(_ textContentStorage: NSTextContentStorage, textParagraphWith range: NSRange) -> NSTextParagraph? {
        // In this method, we'll inject some attributes for display, without modifying the text storage directly.
        var paragraphWithDisplayAttributes: NSTextParagraph? = nil
        
        // First, get a copy of the paragraph from the original text storage.
        let originalText = textContentStorage.textStorage!.attributedSubstring(from: range)
        if originalText.attribute(.commentDepth, at: 0, effectiveRange: nil) != nil {
            // Use white colored text to make our comments visible against the bright background.
            let displayAttributes: [NSAttributedString.Key: AnyObject] = [.font: commentFont, .foregroundColor: commentColor]
            let textWithDisplayAttributes = NSMutableAttributedString(attributedString: originalText)
            // Use the display attributes for the text of the comment itself, without the reaction.
            // The last character is the newline, second to last is the attachment character for the reaction.
            let rangeForDisplayAttributes = NSRange(location: 0, length: textWithDisplayAttributes.length - 2)
            textWithDisplayAttributes.addAttributes(displayAttributes, range: rangeForDisplayAttributes)
            
            // Create our new paragraph with our display attributes.
            paragraphWithDisplayAttributes = NSTextParagraph(attributedString: textWithDisplayAttributes)
        } else {
            return nil
        }
        // If the original paragraph wasn't a comment, this return value will be nil.
        // The text content storage will use the original paragraph in this case.
        return paragraphWithDisplayAttributes
    }
    
    // MARK: - Popover Management
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none // This makes the comment popover view controller present as a popover on iPhone.
    }
    
    func showCommentPopoverForLayoutFragment(_ layoutFragment: NSTextLayoutFragment) {
        fragmentForCurrentComment = layoutFragment
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let popoverVC = storyboard.instantiateViewController(withIdentifier: "CommentPopoverViewController") as? CommentPopoverViewController {
            popoverVC.viewController = self
            popoverVC.modalPresentationStyle = .popover
            popoverVC.preferredContentSize = CGSize(width: 420.0, height: 100.0)
            popoverVC.popoverPresentationController!.sourceView = self.textDocumentView
            popoverVC.popoverPresentationController!.sourceRect = layoutFragment.layoutFragmentFrame
            popoverVC.popoverPresentationController!.permittedArrowDirections = .any
            popoverVC.popoverPresentationController!.delegate = self
            present(popoverVC, animated: true, completion: {
                //..
            })
        }
    }
    
}

