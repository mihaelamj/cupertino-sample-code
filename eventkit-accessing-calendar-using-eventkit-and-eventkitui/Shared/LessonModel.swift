/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The lesson data model.
*/

import SwiftUI

@MainActor
class LessonModel: ObservableObject {
    private var lessons: [Lesson]
    
    /// The date that the user selected in the picker. Its initial value is today's date.
    @Published var selectedDate: Date
    
    /// A list of repeating lessons.
    @Published var repeatingLessons: [Lesson]
    
    /// A list of drop-in lessons associated with a weekday.
    @Published var selectedDayLessons: [Lesson]
    
    init(date: Date) {
       self.lessons = []
       self.selectedDate = date
       self.repeatingLessons = []
       self.selectedDayLessons = []
       Task {
           await load()
       }
   }
    
    /// Filter the lesson array for the specified lesson type.
    func lessons(in type: LessonType) -> [Lesson] {
       let result = lessons.filter({ (lesson: Lesson) in lesson.type == type })
        return result
    }
    
    /// Fetches the drop-in lessons associated with the specified day.
    func selectedDayLessons(type: LessonType) -> [Lesson] {
        // Fetch the week day associated with the current selected date.
        guard let day = LessonDay(rawValue: selectedDate.matchingDay) else { return [] }
        
        // Fetch all drop-in lessons.
        let singleLessons = lessons(in: .single)
        // Fetch the lessons for this day.
        return singleLessons.filter({ (lesson: Lesson) in lesson.days.contains(day) })
    }
    
    /// The user picked a new date. Fetch the lesson slots for this day.
    func updateSelectedDayLessons() {
        selectedDayLessons = selectedDayLessons(type: .single)
    }
    
    private func load() async {
        let result = await loadData()
        lessons = result
        repeatingLessons = lessons(in: .recurring)
        selectedDayLessons = selectedDayLessons(type: .single)
    }
 
    /// Fetch all lesson data.
    private func loadData() async -> [Lesson] {
        var result: [Lesson] = []
        guard let jsonURL = Bundle(for: type(of: self)).url(forResource: "Lessons", withExtension: "json")
        else {
            return result
        }
        
        do {
            let data = try Data(contentsOf: jsonURL, options: .mappedIfSafe)
            result = try JSONDecoder().decode([Lesson].self, from: data)
        } catch {
            print(error.localizedDescription)
        }
        return result
    }
}
