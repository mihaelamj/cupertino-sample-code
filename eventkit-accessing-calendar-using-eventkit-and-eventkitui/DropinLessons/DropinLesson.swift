/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A detail view the app uses to display the metadata for a given drop in lesson.
*/

import SwiftUI

struct DropInLesson: View {
    @State var lesson: Lesson
    @Binding var selection: Lesson?
    
    var body: some View {
        Button {
            selection = lesson
        } label: {
            Label(lesson: lesson, selection: $selection)
        }
        .buttonStyle(.plain)
    }
}

/// Styles the button according to its selection status.
private struct Label: View {
    @State var lesson: Lesson
    @Binding var selection: Lesson?
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text(lesson.startAtDate.timeAsText)
                    .bold()
                    .foregroundStyle(shapeStyle(Color.primary))
            }
        }
        .shadow(radius: selection == lesson ? 4 : 0)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(selection == lesson ?
                      AnyShapeStyle(Color.blue) :
                        AnyShapeStyle(BackgroundStyle()))
        }
        
    }
    
    func shapeStyle<S: ShapeStyle>(_ style: S) -> some ShapeStyle {
        if selection == lesson {
            return AnyShapeStyle(.background)
        } else {
            return AnyShapeStyle(style)
        }
    }
}

struct DropInLesson_Previews: PreviewProvider {
    static var previews: some View {
        DropInLesson(lesson: Lesson.repeatingLessonMock, selection: .constant(nil))
        DropInLesson(lesson: Lesson.repeatingLessonMock, selection: .constant(Lesson.repeatingLessonMock))
    }
}

