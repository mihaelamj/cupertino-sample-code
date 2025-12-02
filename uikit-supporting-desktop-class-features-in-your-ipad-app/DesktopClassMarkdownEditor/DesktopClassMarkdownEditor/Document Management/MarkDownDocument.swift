/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that handles editing of the document content.
*/

import UIKit

class MarkdownDocument: UIDocument {
    var text = String()
    var parsedDocument: ParsedDocument?
    
    /// A handler for retrieving up-to-date text content from the parser.
    /// Called when the document is about to save.
    var willSaveHandler: (() -> String)?
    
    /// A handler for notifying the editor of document changes.
    /// Called when a node manipulation occurs.
    var didUpdateHandler: ((MarkdownDocument, NSRange? /* adjusted selection range */) -> Void)?
    
    // MARK: UIDocument Overrides
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        if let contents = contents as? Data, let textFromData = String(data: contents, encoding: .utf8) {
            text = textFromData
        }
    }
    
    override func contents(forType typeName: String) throws -> Any {
        if let willSave = willSaveHandler {
            text = willSave()
            
            if let data = text.data(using: .utf8) {
                return data
            }
        }
        
        return Data()
    }
    
    // MARK: Markdown Manipulation
    
    func insertTag(_ tag: MarkdownTag, with content: String, at index: Int) {
        if hasUnsavedChanges {
            autosave { didSave in
                if didSave {
                    self.insertTag(tag, with: content, at: index)
                }
            }
        } else {
            let start = text.startIndex
            let textIndex = text.index(start, offsetBy: index)
                        
            text.insert(contentsOf: tag.openMarkdown + tag.midMarkdown + content + tag.closeMarkdown, at: textIndex)
            
            updateChangeCount(.done)
            
            if let updateHandler = didUpdateHandler {
                updateHandler(self, nil)
            }
        }
    }
    
    func insertTag(_ tag: MarkdownTag, at range: NSRange) {
        if hasUnsavedChanges {
            autosave { didSave in
                if didSave {
                    self.insertTag(tag, at: range)
                }
            }
        } else {
            let start = text.startIndex
            let textRange = text.index(start, offsetBy: range.location)..<text.index(start, offsetBy: range.location + range.length)
            let oldString = text[textRange]
            let applicationResult = tag.apply(to: String(oldString))
            
            text.replaceSubrange(textRange, with: applicationResult.taggedText)
            
            updateChangeCount(.done)
            
            if let updateHandler = didUpdateHandler {
                updateHandler(self, NSRange(location: range.location + applicationResult.selectionAdjustment, length: range.length))
            }
        }
    }
    
    func swapTags(for elements: [OutlineElement], with tag: MarkdownTag) {
        for element in elements {
            parsedDocument?.rootNode.swapTagOfNode(withIdentifier: element.nodeIdentifier, with: tag)
        }
        
        updateTextContent()
    }
    
    func duplicate(_ elements: [OutlineElement]) {
        for element in elements {
            parsedDocument?.rootNode.duplicateDescendant(withIdentifier: element.nodeIdentifier)
        }
        
        updateTextContent()
    }
    
    func delete(_ elements: [OutlineElement]) {
        for element in elements {
            parsedDocument?.rootNode.deleteDescendant(withIdentifier: element.nodeIdentifier)
        }
        
        updateTextContent()
    }
    
    // MARK: Internal
    
    private func updateTextContent() {
        text = parsedDocument!.textContent()
        updateChangeCount(.done)
        
        if let updateHandler = didUpdateHandler {
            updateHandler(self, nil)
        }
    }
}
