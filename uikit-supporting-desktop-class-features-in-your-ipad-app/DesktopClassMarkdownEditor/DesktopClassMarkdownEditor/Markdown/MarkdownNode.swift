/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that represents a Markdown node.
*/

import Foundation

class MarkdownNode {
    typealias LookupResult = (parent: MarkdownNode, index: Int)
    
    var children = [MarkdownNode]()
    var textContent = String()
    let tag: MarkdownTag?
    let position: Int
    let identifier: UUID
    
    init(tag: MarkdownTag, beginningAt position: Int = 0) {
        self.tag = tag
        self.position = position
        self.identifier = UUID()
    }
    
    init(text: String = "", beginningAt position: Int = 0) {
        self.tag = nil
        self.textContent = text
        self.position = position
        self.identifier = UUID()
    }
    
    func htmlString() -> String {
        var html = String()

        if children.isEmpty {
            let escapedString = textContent.trimmingCharacters(in: .newlines)
                .replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
            html.append(escapedString)
        } else {
            children.forEach {
                html.append($0.htmlString())
            }
        }
        
        if let markdownTag = tag {
            return markdownTag.generateHTML(with: html)
        } else {
            return html
        }
    }

    var length: Int {
        var length = textContent.count
        if let tag = tag {
            length += tag.openMarkdown.count
            // Don't include newlines in the length
            let trimmedClosingMarkdown = tag.closeMarkdown.trimmingCharacters(in: .newlines)
            length += trimmedClosingMarkdown.count
        }
        return length
    }
    
    var fullText: String {
            if let tag = tag {
                return tag.openMarkdown + textContent + tag.closeMarkdown.trimmingCharacters(in: .newlines)
            } else {
                return textContent
            }
    }
    
    // MARK: Node Manipulation
    
    func deleteDescendant(withIdentifier identifier: UUID) {
        if let lookupResult = findDescendant(withIdentifier: identifier) {
            lookupResult.parent.children.remove(at: lookupResult.index)
        }
    }
    
    func duplicateDescendant(withIdentifier identifier: UUID) {
        if let lookupResult = findDescendant(withIdentifier: identifier) {
            let original = lookupResult.parent.children[lookupResult.index]
            let position = original.position + original.fullText.count
            
            let nodesToInsert = [
                MarkdownNode(text: "\n", beginningAt: position),
                MarkdownNode(text: original.fullText, beginningAt: position + 1)
            ]

            lookupResult.parent.children.insert(contentsOf: nodesToInsert, at: lookupResult.index + 1)
        }
    }
    
    func swapTagOfNode(withIdentifier identifier: UUID, with tag: MarkdownTag) {
        if let lookupResult = findDescendant(withIdentifier: identifier) {
            let foundNode = lookupResult.parent.children[lookupResult.index]
            let replacement = MarkdownNode(tag: tag, beginningAt: foundNode.position)
            
            if tag.options.contains(.wrapsOtherTagsWhenSwappedIn) {
                replacement.textContent = foundNode.fullText
            } else {
                replacement.textContent = foundNode.textContent
            }
            
            lookupResult.parent.children.remove(at: lookupResult.index)
            lookupResult.parent.children.insert(replacement, at: lookupResult.index)
        }
    }
    
    // MARK: Node Lookup
    
    func findDescendant(withIdentifier identifier: UUID) -> LookupResult? {
        for index in 0..<children.count {
            if children[index].identifier == identifier {
                return (self, index)
            }
        }
        
        var parent: LookupResult? = nil
        for child in children {
            parent = child.findDescendant(withIdentifier: identifier)
            
            if parent != nil {
                break
            }
        }
        
        return parent
    }
    
    // MARK: Description
    
    var debugDescription: String {
        var description = ""
        
        if children.isEmpty {
            description = "MarkdownNode : \(textContent.prefix(20))"
        } else {
            for child in children {
                description.append(contentsOf: child.debugDescription)
            }
        }
        
        return description
    }
}
