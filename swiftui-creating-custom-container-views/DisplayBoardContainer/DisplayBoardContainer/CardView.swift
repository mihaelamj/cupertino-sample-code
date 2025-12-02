/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The card view that displays pinned items, such as notes or genres, on the display board.
*/

import SwiftUI

enum DisplayBoardCardScale {
    case normal
    case small
}

struct CardView<Content: View>: View {
    var scale: DisplayBoardCardScale = .normal
    var isRejected: Bool = false
    var rotation: Angle?
    var pinColor: Color?
    @ViewBuilder var content: Content
    
    @State private var defaultRotation: Angle?
    @State private var defaultPinColor: Color?
    
    var body: some View {
        VStack {
            content
                .font(contentFont)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .fixedSize()
        }
        .padding(contentPadding)
        .background { background }
        .overlay {
            if isRejected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.red.opacity(0.95)
                        .shadow(.drop(
                            color: .red.opacity(0.8),
                            radius: 1, x: 3, y: 1)))
                    .frame(width: 20)
                    .rotationEffect(.degrees(45))
            }
        }
        .rotationEffect(rotation ?? defaultRotation ?? .zero)
        .overlay(alignment: .top) {
            PinView()
                .offset(y: -6)
                .foregroundStyle(pinColor ?? defaultPinColor ?? .red)
        }
        .offset(y: -6)
        .task {
            let generator = CardRandomGenerator.main
            defaultRotation = generator.nextCardRotation()
            defaultPinColor = generator.nextCardPinColor()
        }
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
                radius: 2, x: 2, y: 3)),
            in: backgroundShape)
    }
    
    private var contentFont: Font {
        switch scale {
        case .normal: .custom("Noteworthy", size: 32.0, relativeTo: .title)
        case .small: .custom("Noteworthy", size: 28.0, relativeTo: .title)
        }
    }
    
    private var contentPadding: EdgeInsets {
        let padding: CGFloat = 30.0 * (scale == .small ? 0.5 : 1.2)
        return EdgeInsets(
            top: 15 + padding,
            leading: padding,
            bottom: padding,
            trailing: padding)
    }
}
