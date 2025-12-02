/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class that manages view-based text attachments.
*/

#if os(iOS)
import UIKit
typealias View = UIView
#else
import AppKit
typealias View = NSView
#endif

#if os(iOS)
class AttachmentView: UIView {
    var textAttachment: Attachment? = nil
    private var touching: Bool = false

    override var intrinsicContentSize: CGSize {
        var result: CGSize = .init(width: 60.0, height: labelText.size().height)
        result.width += xPadding * 2
        result.height += yPadding * 2
        return result
    }
    
    var xPadding: CGFloat { return 5 }
    var yPadding: CGFloat { return 5 }
    var cornerRadius: CGFloat { return 10 }

    var fillColor: UIColor {
        return touching ? .systemGray : .systemBlue
    }

    var labelText: NSAttributedString {
        let string = (textAttachment?.hiddenContent != nil) ? "Show more" : "Show less"
        var labelFont = UIFont.preferredFont(forTextStyle: .caption2)
        let labelFontDescriptor = labelFont.fontDescriptor.withSymbolicTraits(.traitBold)
        labelFont = UIFont(descriptor: labelFontDescriptor!, size: labelFont.pointSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: UIColor.white
        ]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        touching = true
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        touching = false
        textAttachment?.toggleHidden()
    }
    
    override func draw(_ rect: CGRect) {
        UIColor.systemBackground.set()
        UIRectFill(bounds)
        fillColor.set()
        UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius).fill()
        let labelSize = labelText.size()
        labelText.draw(at: CGPoint(x: bounds.origin.x + (bounds.size.width - labelSize.width) / 2.0, y: bounds.origin.y + yPadding))

    }
}
#else
class AttachmentView: NSView {
    var textAttachment: Attachment? = nil
    private var isMouseDown: Bool = false
    
    override var intrinsicContentSize: NSSize {
        var result: NSSize = .init(width: 60.0, height: labelText.size().height)
        result.width += xPadding * 2
        result.height += yPadding * 2
        return result
    }
    
    var xPadding: CGFloat { return 3 }
    var yPadding: CGFloat { return 1 }
    var cornerRadius: CGFloat { return 3 }

    var fillColor: NSColor {
        return isMouseDown ? .selectedControlColor : .systemBlue
    }

    var labelText: NSAttributedString {
        let string = (textAttachment?.hiddenContent != nil) ? "Show more" : "Show less"
        var labelFont = NSFont.preferredFont(forTextStyle: .caption2, options: [:])
        let labelFontDescriptor = labelFont.fontDescriptor.withSymbolicTraits(.bold)
        labelFont = NSFont(descriptor: labelFontDescriptor, size: labelFont.pointSize)!
        let attributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: NSColor.white
        ]
        return NSAttributedString(string: string, attributes: attributes)
    }
    
    override func mouseDown(with event: NSEvent) {
        isMouseDown = true
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        isMouseDown = false
        textAttachment?.toggleHidden()
    }
    
    override func draw(_ rect: CGRect) {
        NSColor.clear.set()
        bounds.fill()
        fillColor.set()
        NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius).fill()
        let labelSize = labelText.size()
        labelText.draw(at: NSPoint(x: bounds.origin.x + (bounds.size.width - labelSize.width) / 2.0, y: bounds.origin.y + yPadding))
    }
}
#endif

class AttachmentViewProvider: NSTextAttachmentViewProvider {
    override func loadView() {
        let attachmentView = AttachmentView()
        attachmentView.textAttachment = textAttachment as? Attachment
        view = attachmentView
    }
}

class Attachment: NSTextAttachment {
    weak var textLayoutManager: NSTextLayoutManager? = nil
    var hiddenContent: NSAttributedString? = nil
    
    override func viewProvider(for parentView: View?, location: NSTextLocation, textContainer: NSTextContainer?) -> NSTextAttachmentViewProvider? {
        let viewProvider = AttachmentViewProvider(textAttachment: self, parentView: parentView,
                                                  textLayoutManager: textContainer?.textLayoutManager,
                                                  location: location)
        viewProvider.tracksTextAttachmentViewBounds = true
        return viewProvider
    }

    func toggleHidden() {
        guard let textStorage: NSTextStorage = (textLayoutManager?.textContentManager as? NSTextContentStorage)?.textStorage else { return }
        textLayoutManager?.textContentManager?.performEditingTransaction {
            if hiddenContent != nil { // Showing
                let ellipsisRange = NSRange(location: textStorage.length - 2, length: 1)
                textStorage.replaceCharacters(in: ellipsisRange, with: hiddenContent!)
                hiddenContent = nil
            } else { // Hiding
                let firstParagraphRange = NSRange(location: 0, length: 331)
                let hidingRange = NSRange(location: NSMaxRange(firstParagraphRange), length: textStorage.length - NSMaxRange(firstParagraphRange) - 1)
                hiddenContent = textStorage.attributedSubstring(from: hidingRange)
                textStorage.replaceCharacters(in: hidingRange, with: "…")
            }
        }
    }
}
