/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A minimalist implementation of a Markdown parser to generate
 an HTML representation of the document content.
*/

import Foundation

struct ParsedDocument {
    /// A formatted HTML string of the parsed document.
    let html: String

    /// An array of navigatable outline elements.
    let outline: [OutlineElement]
        
    /// This document's root node.
    var rootNode: MarkdownNode
    
    init(nodes: [MarkdownNode]) {
        var innerHTML = String()
        var lastHeadingLevel = 0
        
        self.outline = nodes.compactMap { node in
            innerHTML.append(node.htmlString())

            // For top-level nodes that have an outline representation,
            // create an outline element.
            if let tag = node.tag, let representation = tag.outlineRepresentation {
                // Subtract 1 from the position because of adding a newline to the beginning of the document.
                let range = NSRange(location: node.position - 1, length: node.length)
                let text = node.textContent.trimmingCharacters(in: .whitespacesAndNewlines)
                var indentationLevel = lastHeadingLevel

                if case .heading(let headingLevel) = representation {
                    indentationLevel = max(headingLevel - 1, 0)
                    lastHeadingLevel = headingLevel
                }

                return OutlineElement(
                    representation: representation,
                    range: range,
                    text: text,
                    indendationLevel: indentationLevel,
                    nodeIdentifier: node.identifier)
            }
            
            return nil
        }
        self.html = "<html>\n<meta name=\"viewport\" content=\"user-scalable=no\">\n<head>\n<link rel=\"stylesheet\" href=\"Stylesheet.css\">\n</head>\n<body>\n\(innerHTML)\n</body></html>"

        self.rootNode = MarkdownNode()
        self.rootNode.children = nodes
    }
    
    func textContent() -> String {
        rootNode.children.map { $0.fullText }.joined()
    }
}

class Parser {
    let tags = [
        .heading(6),
        .heading(5),
        .heading(4),
        .heading(3),
        .heading(2),
        .heading(1),
        MarkdownTag(open: "* ", close: "\n", htmlTag: "li", options: .disallowsNewLines),
        MarkdownTag(open: "- ", close: "\n", htmlTag: "li", options: .disallowsNewLines),
        .bold,
        MarkdownTag(open: "__", htmlTag: "strong", options: .disallowsNewLines),
        .italicize,
        MarkdownTag(open: "*", htmlTag: "em", options: .disallowsNewLines),
        .underline,
        .strikethrough,
        .image,
        .link,
        .codeBlock(.swift),
        .codeBlock(.objectiveC),
        .codeBlock(),
        MarkdownTag(open: "`", htmlTag: "code", options: .disallowsNestedTags),
        .blockQuote,
        MarkdownTag(open: "<br", close: "/>", options: .disallowsNestedTags) { _, _ in "<br />" },
        MarkdownTag(open: "<br", close: ">", options: .disallowsNestedTags) { _, _ in "<br />" },
        .comment,
        MarkdownTag(open: "<", mid: "@", close: ">", options: [.disallowsNestedTags, .disallowsNewLines]) { tag, content in
            if content.contains(tag.midMarkdown) {
                return content
            }
            return tag.openMarkdown + content + tag.closeMarkdown
        }
    ]

    func parse(_ markdown: String) -> ParsedDocument {
        let nodes = textParsedAsNodes(markdown)
        return ParsedDocument(nodes: nodes)
    }
    
    /// Recursive parse function with the following algorithm:
    /// - For each character in `text`
    ///     - Compare against the first character in every tag
    ///         - If the first character matches, create a substring from the character to the length of
    ///           the tag's opening Markdown and check if it matches.
    ///             - If it matches, look for the closing tag.
    ///                 - If found, create a node with the substring between the open and close
    ///                   Markdown as its content string, and recursively call the function to obtain
    ///                   its child nodes.
    func textParsedAsNodes(_ text: String) -> [MarkdownNode] {
        let textAsArray = Array(text)
        
        var nodes = [MarkdownNode]()
        var accumulatedString = [String.Element]()
        
        var index = 0

        while index < textAsArray.count {
            let chr = textAsArray[index]
            var didIncrement = false
            
            tags.forEach {
                let openTag = Array($0.openMarkdown)

                if chr == openTag[0] {
                    let endIndex = min(index + openTag.count, textAsArray.endIndex)
                    let substring = textAsArray[index..<endIndex]
                    
                    if substring.elementsEqual(openTag) {
                        if accumulatedString.isEmpty == false {
                            nodes.append(MarkdownNode(text: String(accumulatedString), beginningAt: index))
                            accumulatedString = [String.Element]()
                        }
                        
                        let closeTag = Array($0.closeMarkdown)
                        
                        let foundNode = MarkdownNode(tag: $0, beginningAt: index)
                        let afterOpenTagIdx = index + openTag.count
                        if let closeTagStartIdx = find(closeTag, from: afterOpenTagIdx, inString: textAsArray, allowingNewlines: !$0.options.contains(.disallowsNewLines)) {
                            foundNode.textContent = String(textAsArray[afterOpenTagIdx..<closeTagStartIdx])
                            if !$0.options.contains(.disallowsNestedTags) {
                                foundNode.children = textParsedAsNodes(foundNode.textContent)
                            }
                            
                            index = closeTagStartIdx
                            
                            // Allow parsing of new lines in following
                            // iterations of the loop to properly detect tags
                            // that begin on a new line. Otherwise, increment
                            // `index` to advance past the closing Markdown.
                            if $0.closeMarkdown != "\n" {
                                index += closeTag.count
                            }
                            
                            didIncrement = true

                            nodes.append(foundNode)
                        }
                        
                        index = min(index, textAsArray.endIndex)
                        return
                    }
                }
                
                index = min(index, textAsArray.endIndex)
            }

            if !didIncrement {
                accumulatedString.append(chr)
                index += 1
            }
        }
        
        if accumulatedString.isEmpty == false {
            nodes.append(MarkdownNode(text: String(accumulatedString), beginningAt: index))
        }
        
        return nodes
    }
        
    func find(_ query: [String.Element], from: Int, inString: [String.Element], allowingNewlines: Bool = true) -> Int? {
        for index in from..<inString.count {
            if inString[index] == query[0] {
                let substring = inString[index..<min(index + query.count, inString.endIndex)]
                if String(substring) == String(query) {
                    return index
                }
            } else if !allowingNewlines && inString[index] == "\n" {
                return nil
            }
            
            if index == (inString.count - query.count) {
                break
            }
        }

        return nil
    }
}
