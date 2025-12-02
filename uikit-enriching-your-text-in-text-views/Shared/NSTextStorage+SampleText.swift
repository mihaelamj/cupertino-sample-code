/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The extension that loads the sample text.
*/

#if os(iOS)
import UIKit
private let textColor = UIColor.label
#else
import AppKit
private let textColor = NSColor.textColor
#endif

extension NSTextStorage {
    // Load the surrounding text for the exclusion path.
    func loadExclusionPathSampleText() {
        guard let fileURL = Bundle.main.url(forResource: "ExclusionPathSample", withExtension: "rtf") else {
            fatalError("Failed to find ExclusionPathSample.rtf in the app bundle.")
        }
        let options = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf]
        guard let sampleText = try? NSAttributedString(url: fileURL, options: options, documentAttributes: nil) else {
            fatalError("Failed to load sample text.")
        }
        replaceCharacters(in: NSRange(location: 0, length: length), with: sampleText)
        addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: length))
    }
    
    // Set up a view-based text attachment.
    func loadAttachmentSampleText(textLayoutManager: NSTextLayoutManager) {
        
        guard let fileURL = Bundle.main.url(forResource: "AttachmentSample", withExtension: "rtf") else {
            fatalError("Failed to find AttachmentSample.rtf in the app bundle.")
        }
        let options = [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.rtf]
        guard let sampleText = try? NSAttributedString(url: fileURL, options: options, documentAttributes: nil) else {
            fatalError("Failed to load sample text.")
        }
        replaceCharacters(in: NSRange(location: 0, length: length), with: sampleText)
        addAttribute(.foregroundColor, value: textColor, range: NSRange(location: 0, length: length))

        let attachment = Attachment()
        attachment.allowsTextAttachmentView = true
        attachment.textLayoutManager = textLayoutManager
        let attachmentAttributedString = NSAttributedString(attachment: attachment)
        append(attachmentAttributedString)
    }
    
    // Set up a sample list.
    func loadListSampleText() {
        guard let fileURL = Bundle.main.url(forResource: "ListSample", withExtension: "txt") else {
            fatalError("Failed to find ListSample.txt in the app bundle.")
        }
        guard let sampleText = try? String(String(contentsOf: fileURL)) else {
            fatalError("Failed to load sample text.")
        }
        let sampleContents = NSAttributedString(string: sampleText)
        replaceCharacters(in: NSRange(location: 0, length: length), with: sampleContents)
    
        guard let paragraphStyle = NSParagraphStyle.default.mutableCopy() as? NSMutableParagraphStyle else {
            return
        }
        let textList = NSTextList(markerFormat: .decimal, options: 0)
        paragraphStyle.textLists = [textList]

        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .foregroundColor: textColor
        ]

        let listAttributedString = NSAttributedString(string: string, attributes: attributes)
        replaceCharacters(in: NSRange(location: 0, length: length), with: listAttributedString)
    }
    
    // Change the list marker style for the text lists, if any.
    func setListMarkerStyle(styleIndex: Int) {
        guard styleIndex >= 0 && styleIndex < 3 else {
            return
        }
        let markerFormats: [NSTextList.MarkerFormat] = [.decimal, .disc, .square]
        let newMarkerFormat = markerFormats[styleIndex]

        var pos = 0
        while pos < length {
            var pstyleRange = NSRange(location: NSNotFound, length: 0)
            let searchRange = NSRange(location: pos, length: length - pos)
            let value = attribute(.paragraphStyle, at: pos, longestEffectiveRange: &pstyleRange, in: searchRange)
            if let pstyle = value as? NSParagraphStyle {
                if !pstyle.textLists.isEmpty, let mutablePstyle = pstyle.mutableCopy() as? NSMutableParagraphStyle {
                    mutablePstyle.textLists = mutablePstyle.textLists.map { textList in
                        NSTextList(markerFormat: newMarkerFormat, options: 0)
                    }
                    addAttribute(.paragraphStyle, value: mutablePstyle, range: pstyleRange)
                }
            }
            pos = NSMaxRange(pstyleRange)
        }
    }
}
