/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements view modifiers.
*/

import SwiftUI

struct OpaqueBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                    .foregroundStyle(.black)
                    .opacity(0.05)
                    .padding(-10)
            }
            .padding(20)
    }
}

struct SubheadlineTextFormat: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .textCase(.uppercase)
            .foregroundStyle(.gray)
    }
}

struct PaddedSubheadlineTextFormat: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .textCase(.uppercase)
            .foregroundStyle(.gray)
            .padding(.top, 10)
            .padding(.leading, 10)
    }
}

struct PaddedTitle2TextFormat: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title2)
            .padding(.top, 10)
            .padding(.bottom, 10)
    }
}

extension View {
    func opaqueBackground() -> some View {
        modifier(OpaqueBackground())
    }
    
    func subheadlineTextFormat() -> some View {
        modifier(SubheadlineTextFormat())
    }
    
    func paddedSubheadlineTextFormat() -> some View {
        modifier(PaddedSubheadlineTextFormat())
    }
    
    func paddedTitle2TextFormat() -> some View {
        modifier(PaddedTitle2TextFormat())
    }
}
