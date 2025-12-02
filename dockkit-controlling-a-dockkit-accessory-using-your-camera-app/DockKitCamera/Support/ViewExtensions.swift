/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Extensions and supporting SwiftUI types.
*/

import SwiftUI
import UIKit

let largeButtonSize = CGSize(width: 64, height: 64)
let smallButtonSize = CGSize(width: 32, height: 32)

struct ClearRectangleWithBorder: View {
    let rect: CGRect
    
    var body: some View {
        let path = Path(rect)
        path.fill(Color.clear).overlay(path.stroke(Color.black, lineWidth: 2))
    }
}

struct DefaultButtonStyle: ButtonStyle {
    
    @Environment(\.isEnabled) private var isEnabled: Bool

    enum Size: CGFloat {
        case small = 22
        case large = 24
    }
    
    private let size: Size
    
    init(size: Size) {
        self.size = size
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isEnabled ? .primary : Color(white: 0.4))
            .font(.system(size: size.rawValue))
            // Pad the buttons on devices that use the `regular` size class,
            // and also when explicitly requesting large buttons.
            .padding(size == .large ? 10.0 : 0)
            .background(.black.opacity(0.4))
            .clipShape(size == .small ? AnyShape(Rectangle()) : AnyShape(Circle()))
    }
}

extension View {
    func hidden(_ shouldHide: Bool) -> some View {
        opacity(shouldHide ? 0 : 1)
    }
}

extension Image {
    init(_ image: CGImage) {
        self.init(uiImage: UIImage(cgImage: image))
    }
}
