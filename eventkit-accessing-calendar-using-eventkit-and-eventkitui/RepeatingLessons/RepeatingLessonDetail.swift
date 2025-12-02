/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A detail view the app uses to display the metadata (recurrence interval and frequency, starting and end time, and name) for a given repeating
    lesson.
*/

import SwiftUI

struct RepeatingLessonDetail: View {
    @State var lesson: Lesson
    
    var body: some View {
        HStack {
            Text(lesson.name)
                .foregroundColor(.primary)
                .font(.headline)
            VStack(alignment: .leading, spacing: 3) {
                // Display the days of the week on which the lesson takes place.
                Text(lesson.daysAsText)
                    .foregroundColor(.primary)
                    .font(.caption)
                
                // Display the beginning and end time of the lesson.
                Text(lesson.fromStartAtToEndAtAsText)
                    .foregroundStyle(.primary)
                    .font(.caption)
                
                // Display how often the lesson occurs.
                Text(lesson.numberOfRecurringLessons)
                    .frame(maxWidth: .infinity, alignment: .bottomTrailing)
                    .foregroundStyle(.secondary)
                    .font(.caption2)
            }
        }
    }
}

struct RepeatingLessonDetail_Previews: PreviewProvider {
    static var previews: some View {
        RepeatingLessonDetail(lesson: Lesson.repeatingLessonMock)
    }
}
