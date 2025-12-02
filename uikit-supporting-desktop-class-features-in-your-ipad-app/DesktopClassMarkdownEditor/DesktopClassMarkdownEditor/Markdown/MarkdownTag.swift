/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that represents a Markdown tag.
*/

import UIKit

struct MarkdownTag {
    struct Options: OptionSet {
        let rawValue: Int

        static let disallowsNestedTags          = Options(rawValue: 1 << 0)
        static let disallowsNewLines            = Options(rawValue: 1 << 1)
        static let isBlock                      = Options(rawValue: 1 << 2)
        static let wrapsOtherTagsWhenSwappedIn  = Options(rawValue: 1 << 4)
    }
    
    enum Language: String, CaseIterable {
        case swift = "Swift"
        case objectiveC = "Objective-C"
        case unspecified = "Unspecified"

        var image: UIImage? {
            var imageName: String
            switch self {
            case .swift:
                imageName = "swift"
            case .objectiveC:
                imageName = "curlybraces"
            case .unspecified:
                imageName = "chevron.left.forwardslash.chevron.right"
            }
            return UIImage(systemName: imageName)
        }
    }
    
    let openMarkdown: String
    let midMarkdown: String
    let closeMarkdown: String
    let htmlTag: String
    
    let options: Options
    let outlineRepresentation: OutlineRepresentation?
    private let htmlTransformer: ((MarkdownTag, String) -> String)?

    /**
     * @abstract Creates a MarkdownTag
     *
     * @param openMarkdown     Opening Markdown.
     * @param midMarkdown      Optional middle Markdown for complex tags.
     * @param closeMarkdown    Optional closing Markdown. Defaults to the opening Markdown when ommitted.
     * @param htmlTag          HTML tag to use when generating HTML.
     * @param options          Tag options.
     * @param options          Tag OutlineRepresentation.
     * @param htmlTransformer  Closure for transforming a string into HTML for complex tags. When present, this supersedes the htmlTag.
     */
    init(open: String,
         mid: String = "",
         close: String? = nil,
         htmlTag: String = "",
         options: Options = [],
         outlineRepresentation: OutlineRepresentation? = nil,
         htmlTransformer: ((MarkdownTag, String) -> String)? = nil) {
        
        self.openMarkdown = open
        self.midMarkdown = mid
        if let closeTag = close {
            self.closeMarkdown = closeTag
        } else {
            self.closeMarkdown = open
        }
        self.htmlTag = htmlTag
        self.options = options
        self.outlineRepresentation = outlineRepresentation
        self.htmlTransformer = htmlTransformer
    }
    
    func generateHTML(with text: String) -> String {
        if let transformer = htmlTransformer {
            return transformer(self, text)
        }
        
        return "<\(htmlTag)>\(text)</\(htmlTag)>"
    }
    
    func apply(to text: String) -> (taggedText: String, selectionAdjustment: Int) {
        let isBlock = options.contains(.isBlock)
        let openTagString = isBlock ? "\n\(openMarkdown)\n" : openMarkdown
        let closeTagString = isBlock ? "\n\(closeMarkdown)\n" : closeMarkdown
                
        return (openTagString + text + midMarkdown + closeTagString, openTagString.count)
    }
    
    static var link: Self {
        MarkdownTag(open: "[", mid: "](", close: ")") { tag, content in
            if content.contains(tag.midMarkdown), let midIndex = content.firstIndex(of: "]") {
                let text = content[..<midIndex]
                let url = content[content.index(midIndex, offsetBy: tag.midMarkdown.count)...]
                return "<a href=\"\(url)\">\(text)</a>"
            }
            
            return tag.openMarkdown + content + tag.closeMarkdown
        }
    }
    
    static var image: Self {
        MarkdownTag(open: "![", mid: "](", close: ")", options: .disallowsNestedTags) { tag, content in
            if content.contains(tag.midMarkdown), let midIndex = content.firstIndex(of: "]") {
                let alt = content[..<midIndex]
                var src = String(content[content.index(midIndex, offsetBy: tag.midMarkdown.count)...])

                if !src.hasPrefix("http") {
                    let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    src = docsDir.appendingPathComponent(src).absoluteString
                }
                                
                return "<p><img alt=\"\(alt)\" src=\"\(src)\"></p>"
            }
            
            return tag.openMarkdown + content + tag.closeMarkdown
        }
    }
    
    static var bold: Self {
        MarkdownTag(open: "**", htmlTag: "strong", options: .disallowsNewLines)
    }
    
    static var italicize: Self {
        MarkdownTag(open: "_", htmlTag: "em", options: .disallowsNewLines)
    }
    
    static var underline: Self {
        MarkdownTag(open: "<u>", close: "</u>", htmlTag: "u")
    }
    
    static var strikethrough: Self {
        MarkdownTag(open: "~~", htmlTag: "strike")
    }
    
    static var blockQuote: Self {
        MarkdownTag(open: ">", close: "\n", htmlTag: "blockquote", options: .isBlock)
    }
    
    static var comment: Self {
        MarkdownTag(open: "<!--", close: "-->", options: [.disallowsNestedTags, .wrapsOtherTagsWhenSwappedIn]) { tag, content in
            "<!--\(content)-->"
        }
    }
    
    static func heading(_ level: Int) -> Self {
        let openMarkdown = String(repeating: "#", count: level)
        return MarkdownTag(open: openMarkdown, close: "\n", htmlTag: "H\(level)", outlineRepresentation: .heading(level))
    }
    
    static func codeBlock(_ language: Language = .unspecified) -> Self {
        let options: MarkdownTag.Options = [ .disallowsNestedTags, .isBlock ]
        let languageName = (language == .unspecified) ? "" : language.rawValue.lowercased()
        
        return MarkdownTag(open: "```\(languageName)", close: "```", options: options, outlineRepresentation: .codeBlock(language)) { tag, content in
            "<div class=\"\(languageName)\"><div class=\"language-tag\"></div><pre><code>\(content)</code></pre></div>\n"
        }
    }
}
