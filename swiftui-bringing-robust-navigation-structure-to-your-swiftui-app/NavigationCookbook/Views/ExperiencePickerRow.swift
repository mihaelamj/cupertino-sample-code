/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A navigation experience picker row that displays the icon, name, and
 description for each experience.
*/

import SwiftUI

struct ExperiencePickerItem: View {
    @Binding var selection: Experience?
    var experience: Experience
    
    var body: some View {
        Button {
            selection = experience
        } label: {
            Label(selection: $selection, experience: experience)
        }
        .buttonStyle(.plain)
    }
}

private struct Label: View {
    @Binding var selection: Experience?
    var experience: Experience
    @State private var isHovering = false
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: experience.imageName)
                .font(.title)
                .foregroundStyle(shapeStyle(Color.accentColor))
            VStack(alignment: .leading) {
                Text(experience.localizedName)
                    .bold()
                    .foregroundStyle(shapeStyle(Color.primary))
                Text(experience.localizedDescription)
                    .font(.callout)
                    .lineLimit(3, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(shapeStyle(Color.secondary))
            }
        }
        .shadow(radius: selection == experience ? 4 : 0)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(selection == experience ?
                      AnyShapeStyle(Color.accentColor) :
                        AnyShapeStyle(BackgroundStyle()))
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isHovering ? Color.accentColor : .clear)
        }
        .scaleEffect(isHovering ? 1.02 : 1)
        .onHover { isHovering in
            withAnimation {
                self.isHovering = isHovering
            }
        }
    }
    
    func shapeStyle<S: ShapeStyle>(_ style: S) -> some ShapeStyle {
        if selection == experience {
            return AnyShapeStyle(.background)
        } else {
            return AnyShapeStyle(style)
        }
    }
}

#Preview() {
    ForEach(Experience.allCases) {
        ExperiencePickerItem(selection: .constant($0), experience: $0)
    }
}
