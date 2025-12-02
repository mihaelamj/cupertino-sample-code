/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions that add convenience methods to SwiftUI.
*/

import SwiftUI
import Combine

extension NotificationCenter {
    var storeDidChangePublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .cdcksStoreDidChange).receive(on: DispatchQueue.main)
    }
}

/**
 Layout constants.
 */
struct Layout {
    static let sheetIdealWidth = 400.0
    static let sheetIdealHeight = 500.0
    
    #if os(macOS)
    static let sectionHeaderPadding: Edge.Set = [.leading]
    #else
    static let sectionHeaderPadding: Edge.Set = []
    #endif
    
    #if os(watchOS)
    static let gridItemSize = CGSize(width: 168, height: 148)
    #else
    static let gridItemSize = CGSize(width: 118, height: 118)
    #endif
}

/**
 Only use Divider in a contextual menu for iOS and macOS.
 */
#if os(watchOS)
typealias MenuDivider = EmptyView
typealias MenuScrollView = ScrollView
#else
typealias MenuDivider = Divider
typealias MenuScrollView = Group
#endif

#if os(iOS)
typealias ApplicationDelegateAdaptor = UIApplicationDelegateAdaptor
#elseif os(macOS)
typealias ApplicationDelegateAdaptor = NSApplicationDelegateAdaptor
#endif

#if os(macOS)
/**
 Align NSImage to UIImage so the code that uses UIImage can work in macOS.
 */
typealias UIImage = NSImage

extension Image {
    init(uiImage: UIImage) {
        self.init(nsImage: uiImage)
    }
}

extension NSImage {
    convenience init(cgImage: CGImage) {
        self.init(cgImage: cgImage, size: .zero)
    }
    
    func jpegData(compressionQuality: CGFloat) -> Data? {
        let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: .jpeg, properties: [:])!
    }
}
#endif

extension Color {
    static var gridItemBackground: Color {
        #if os(iOS)
        return Color(.systemGray6)
        #else
        return Color.gray
        #endif
    }
}

extension ToolbarItemPlacement {
    static let dismiss = cancellationAction
    #if os(iOS)
    static let firstItem = navigationBarTrailing
    static let secondItem = bottomBar
    #else
    static let firstItem = automatic
    static let secondItem = automatic
    #endif
}

#if os(macOS)
extension ListStyle where Self == InsetListStyle {
    static var clearRowShape: InsetListStyle {
        InsetListStyle(alternatesRowBackgrounds: true)
    }
}
#else
extension ListStyle where Self == PlainListStyle {
    static var clearRowShape: PlainListStyle {
        PlainListStyle()
    }
}
#endif

/**
 A menu button label that aligns its icon and title in watchOS.
 */
struct MenuButtonLabel: View {
    struct WatchMenuLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.icon
                    .frame(width: 30)
                configuration.title
                Spacer()
            }
        }
    }

    let title: String
    let systemImage: String
    
    var body: some View {
        #if os(watchOS)
        Label(title, systemImage: systemImage)
            .labelStyle(WatchMenuLabelStyle())
        #else
        Label(title, systemImage: systemImage)
            .labelStyle(.titleAndIcon)
        #endif
    }
}

/**
 A  button label with the appropriate style for a toolbar item in a sheet.
 */
struct SheetToolbarItemLabel: View {
    let title: String
    let systemImage: String
    
    var body: some View {
        #if os(macOS)
        Label(title, systemImage: systemImage)
            .labelStyle(.titleOnly)
        #else
        Label(title, systemImage: systemImage)
            .labelStyle(.iconOnly)
        #endif
    }
}

/**
 A view modifier that prompts a message if the list is empty.
 */
struct EmptyListModifier: ViewModifier {
    let isEmpty: Bool
    let prompt: String

    @ViewBuilder
    func body(content: Content) -> some View {
        if isEmpty {
            Spacer()
                .frame(maxWidth: .infinity)
                .overlay {
                    Text(prompt)
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.secondary)
                }
        } else {
            content
        }
    }
}

extension View {
    func emptyListPrompt(_ isEmpty: Bool, prompt: String = "No data.") -> some View {
        modifier(EmptyListModifier(isEmpty: isEmpty, prompt: prompt))
    }
}

/**
 A  button with a system icon only and the appropriate style for different platforms.
 */
struct IconOnlyButton: View {
    let title: String
    let systemImage: String
    var font: Font?
    let action: () -> Void
    
    init(_ title: String, systemImage: String, font: Font? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.font = font
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(font)
                .labelStyle(.iconOnly)
        }
        #if os(watchOS)
        .buttonStyle(.plain)
        #else
        .buttonStyle(.borderless)
        #endif
    }
}

/**
 A text field that has a clear button for watchOS.
 */
struct ClearableTextField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        #if os(watchOS)
        ZStack(alignment: .leading) {
            GeometryReader { geometry in
                TextFieldLink(text.isEmpty ? title: text) { userInput in
                    text = userInput
                }
                .foregroundColor(.secondary)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .buttonStyle(.borderless)
                
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark")
                        .frame(width: 30, height: geometry.size.height)
                }
                .buttonStyle(.borderless)
                .opacity(text.isEmpty ? 0 : 1)
            }
        }
        #else
        TextField(title, text: $text)
        #endif
    }
}
