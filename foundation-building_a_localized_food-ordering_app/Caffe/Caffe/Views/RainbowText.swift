/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that shows text in multiple colors for ranges of text that have the rainbow attribute.
*/

import SwiftUI

struct RainbowText: View {
    private var attributedString: AttributedString
    
    private var font: Font = .system(.body)
    
    private static let colors: [RainbowAttribute.Value: [Color]] = [
        .plain: [
            .rainbowGraphite,
            .rainbowPacificBlue,
            .rainbowSilver
        ],
        .fun: [
            .rainbowYellow,
            .rainbowOrange,
            .rainbowRed,
            .rainbowPurple,
            .rainbowBlue
        ],
        .extreme: [
            .rainbowBlue,
            .rainbowTeal,
            .rainbowRed,
            .rainbowSilver,
            .rainbowYellow,
            .rainbowOrange,
            .rainbowPurple
        ]
    ]
    
    var body: some View {
        Text(attributedString).font(font)
    }
    
    init(withAttributedString attributedString: AttributedString) {
        self.attributedString = RainbowText.annotateRainbowColors(from: attributedString)
    }

    init(_ localizedKey: String.LocalizationValue) {
        attributedString = RainbowText.annotateRainbowColors(
            from: AttributedString(localized: localizedKey, including: \.caffeApp))
    }

    func font(_ font: Font) -> RainbowText {
        var selfText = self
        selfText.font = font
        return selfText
    }

    private static func annotateRainbowColors(from source: AttributedString) -> AttributedString {
        var attrString = source
        for run in attrString.runs {
            guard let rainbowMode = run.rainbow else {
                continue
            }
            let currentRange = run.range
            var index = currentRange.lowerBound
            let rainbow: [Color] = colors[rainbowMode]!
            var colorCounter: Int = 0
            while index < currentRange.upperBound {
                let nextIndex = attrString.characters.index(index, offsetBy: 1)
                attrString[index ..< nextIndex].foregroundColor = rainbow[colorCounter]
                colorCounter += 1
                if colorCounter >= rainbow.count {
                    colorCounter = 0
                }
                index = nextIndex
            }
        }
        return attrString
    }
}

enum RainbowAttribute: CodableAttributedStringKey, MarkdownDecodableAttributedStringKey {
    enum Value: String, Codable, Hashable {
        case plain
        case fun
        case extreme
    }
    
    static var name: String = "rainbow"
}

extension AttributeScopes {
    struct CaffeAppAttributes: AttributeScope {
        let rainbow: RainbowAttribute
    }
    
    var caffeApp: CaffeAppAttributes.Type { CaffeAppAttributes.self }
}

extension AttributeDynamicLookup {
    subscript<T: AttributedStringKey>(dynamicMember keyPath: KeyPath<AttributeScopes.CaffeAppAttributes, T>) -> T {
        self[T.self]
    }
}

struct RainbowText_Previews: PreviewProvider {
    static var previews: some View {
        guard let previewText = try? AttributedString(markdown: "Some ^[rainbow](rainbow: 'fun') text.",
                                                      including: \.caffeApp) else {
            return RainbowText(withAttributedString: "Couldn't load the preview text.")
        }
        return RainbowText(withAttributedString: previewText)
    }
}
