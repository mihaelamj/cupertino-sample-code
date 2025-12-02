/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Book cover view that displays an image or a rendered graphic and title overlay.
*/

import SwiftUI

struct BookCover: View {
    var book: Book
    var size: CGFloat
    
    var image: Image {
        Image(book.coverName)
            .resizable()
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .strokeBorder(strokeBorderStyle, lineWidth: 2)
            .overlay(alignment: .bottomLeading) {
                Title(book: book, fontSize: size / 12)
                    .padding(padding / 2)
            }
            .padding(padding / 2)
            .background {
                Initial(book: book, fontSize: size)
            }
            .frame(width: size * 0.67, height: size)
            .overlay {
                image
            }
    }
    
    var strokeBorderStyle: some ShapeStyle {
        .background.blendMode(.colorDodge).opacity(0.5).shadow(.drop(radius: 3))
    }
    
    var padding: CGFloat {
        size / 16
    }
}

private struct Title: View {
    var book: Book
    var fontSize: CGFloat
    
    var body: some View {
        Text(book.title)
            .font(font)
            .minimumScaleFactor(0.25)
            .foregroundStyle(.background)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .shadow(radius: 3)
    }
    
    var font: Font {
        .system(size: fontSize, weight: .medium, design: .rounded)
    }
}

private struct Initial: View {
    var book: Book
    var fontSize: CGFloat
    
    var body: some View {
        roundedRectangle
            .fill(book.color)
            .shadow(radius: 3, y: 3)
            .overlay {
                Text(initial)
                    .font(font)
                    .blendMode(.colorDodge)
                    .foregroundStyle(foregroundStyle)
                    .clipShape(roundedRectangle)
            }
    }
    
    var roundedRectangle: some Shape {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
    }
    
    var initial: String {
        let title = book.title
        let offset = title.hasPrefix("The ") ? 4 : 0
        let index = title.index(title.startIndex, offsetBy: offset)
        let character = title[index]
        return String(character)
    }
    
    var font: Font {
        .system(size: fontSize, weight: .ultraLight, design: .serif)
    }
    
    var foregroundStyle: some ShapeStyle {
        .background
        .blendMode(.colorDodge)
        .opacity(0.4)
        .shadow(.drop(radius: 3))
    }
}

struct BookCover_Previews: PreviewProvider {
    static var previews: some View {
        BookCover(book: CurrentlyReading.mock.book, size: 216)
    }
}
