/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A platform-independent representable container.
*/

import SwiftUI

// MARK: - Platform Specific View Types.
#if os(iOS) || os(tvOS)
public typealias PlatformViewRepresentable = UIViewRepresentable
public typealias PlatformView = UIView
#elseif os(macOS)
public typealias PlatformViewRepresentable = NSViewRepresentable
public typealias PlatformView = NSView
#endif

// MARK: - ViewRepresentable
/// A platform-independent SwiftUI representable view.
public protocol ViewRepresentable: PlatformViewRepresentable {

    associatedtype ViewType: PlatformView

    @MainActor
    func makeView(context: Context) -> ViewType

    @MainActor
    func updateView(_ view: ViewType, context: Context)

    @MainActor
    static func dismantleView(_ view: ViewType, coordinator: Coordinator)

    @MainActor
    func sizeThatFits(_ proposal: ProposedViewSize, view: ViewType, context: Context) -> CGSize?
}

// Provide default implementations for the platform-specific representable methods.
@MainActor
public extension ViewRepresentable {
#if os(iOS) || os(tvOS)
    func makeUIView(context: Context) -> ViewType {
        makeView(context: context)
    }

    func updateUIView(_ uiView: ViewType, context: Context) {
        updateView(uiView, context: context)
    }

    static func dismantleUIView(_ uiView: ViewType, coordinator: Coordinator) {
        dismantleView(uiView, coordinator: coordinator)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: ViewType, context: Context) -> CGSize? {
        sizeThatFits(proposal, view: uiView, context: context)
    }
#elseif os(macOS)

    func makeNSView(context: Context) -> ViewType {
        makeView(context: context)
    }

    func updateNSView(_ nsView: ViewType, context: Context) {
        updateView(nsView, context: context)
    }

    static func dismantleNSView(_ nsView: ViewType, coordinator: Coordinator) {
        dismantleView(nsView, coordinator: coordinator)
    }

    @available(macOS 13.0, *)
    func sizeThatFits(_ proposal: ProposedViewSize, nsView: ViewType, context: Context) -> CGSize? {
        sizeThatFits(proposal, view: nsView, context: context)
    }
#endif
}

@MainActor
public extension ViewRepresentable {

    static func dismantleView(_ view: ViewType, coordinator: Coordinator) { }

    func sizeThatFits(_ proposal: ProposedViewSize, view: ViewType, context: Context) -> CGSize? {
        if let width = proposal.width, let height = proposal.height {
            return CGSize(width: width, height: height)
        } else {
            return nil
        }
    }
}
