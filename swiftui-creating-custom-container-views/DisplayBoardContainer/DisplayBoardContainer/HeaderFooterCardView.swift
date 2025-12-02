/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header and footer card views of the main display board.
*/

import SwiftUI

struct HeaderCardView<Content: View>: View {
    var pinColor: Color?
    @ViewBuilder var content: Content

    var body: some View {
        HeaderFooterCardView(isHeader: true, pinColor: pinColor) {
            content
        }
    }
}

struct FooterCardView<Content: View>: View {
    var pinColor: Color?
    @ViewBuilder var content: Content

    var body: some View {
        HeaderFooterCardView(isHeader: false, pinColor: pinColor) {
            content
        }
    }
}

private struct HeaderFooterCardView<Content: View>: View {
    var isHeader: Bool
    var pinColor: Color?
    @ViewBuilder var content: Content

    var body: some View {
        VStack {
            cardContent
        }
        .padding(.horizontal, isHeader ? 30 : 20)
        .padding(.vertical, 10)
        .frame(maxWidth: isHeader ? nil : .infinity)
        .background { background }
        .overlay(alignment: .topLeading) { pin }
        .overlay(alignment: .topTrailing) { pin }
        .overlay(alignment: .bottomTrailing) { pin }
        .overlay(alignment: .bottomLeading) { pin }
    }

    @ViewBuilder
    private var cardContent: some View {
        content
            .font(isHeader ? .title : .headline)
            .fontWeight(.bold)
            .italic(!isHeader)
            .foregroundStyle(isHeader ? Color.primary : .secondary)
            .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private var background: some View {
        let backgroundShape = RoundedRectangle(cornerRadius: 8)

        ZStack {
            backgroundShape
                .inset(by: 2)
                .fill(.white)
            backgroundShape
                .strokeBorder(.black, lineWidth: 2)
        }
        .background(
            .white.shadow(.drop(
                color: .black.opacity(0.3),
                radius: 2, x: 1, y: 2)),
            in: backgroundShape)
    }

    @ViewBuilder
    private var pin: some View {
        PinView(radius: 5)
            .frame(width: 20, height: 20)
            .foregroundStyle(pinColor ?? .red)
    }
}
