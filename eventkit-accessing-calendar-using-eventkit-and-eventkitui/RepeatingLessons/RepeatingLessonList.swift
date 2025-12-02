/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to display a list of recurring lessons.
*/

import EventKit
import SwiftUI

struct RepeatingLessonList: View {
    @State private var selection: Lesson?
    @State var showCalendarChooser = false
    @ObservedObject var model: LessonModel
    
    /// Keeps track of the calendars that the user selected in the calendar chooser.
    @State private var calendar: EKCalendar?
    @EnvironmentObject var storeManager: EventStoreManager
    
    @State private var shouldPresentError: Bool = false
    @State private var alertMessage: String?
    @State private var alertTitle: String?
    
    var body: some View {
        NavigationStack {
            VStack {
                if model.repeatingLessons.isEmpty {
                    MessageView(message: .lessons)
                } else {
                    List(model.repeatingLessons, id: \.self, selection: $selection) { lesson in
                        RepeatingLessonDetail(lesson: lesson)
                    }
                    .listStyle(.plain)
                }
            }
            .toolbar(content: toolbarContent)
            .alertErrorMessage(message: alertMessage, title: alertTitle, isPresented: $shouldPresentError)
            .sheet(isPresented: $showCalendarChooser) {
                CalendarChooser(calendar: $calendar)
            }
            .navigationTitle("Repeating lessons")
        }
        /*
            The lesson model loads lessons from a json file.
            The app turns on the booking button when loading succeeds and turns it off when loading fails.
        */
        if !model.repeatingLessons.isEmpty {
            BookingButton(selection: $selection, action: bookLesson)
        }
    }
    
    /*
        The system calls this function when the user taps the booking button. The app first verifies its authorization status for the user's calendar
        events. If the app has a authorized, write-only, or full access authorization status, it saves the selected lesson to the user' selected
        calendar. If saving fails, the app shows an alert with the reason. If the app has a authorization status that can't be determined, it prompts
        the user for Calendar access. If its authorization status is denied or restricted, the app shows an alert that provides the reason.
     */
    func bookLesson() {
        guard let lesson = selection else { return }
        
        Task {
            do {
                if !storeManager.isWriteOnlyOrFullAccessAuthorized {
                    try await storeManager.setupEventStore()
                }
                
                try await storeManager.saveLesson(lesson, date: model.selectedDate, calendar: calendar)
                selection = nil
            } catch {
                selection = nil
                showError(error, title: "Save failed.")
            }
        }
    }

    /// Sets up details for the alert message to be presented.
    func showError(_ error: Error, title: String) {
        alertTitle = title
        alertMessage = error.localizedDescription
        shouldPresentError = true
    }
}

struct RepeatingLessonList_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject private var model = LessonModel(date: Date())
        
        var body: some View {
            RepeatingLessonList(model: LessonModel(date: Date()))
                .environmentObject(EventStoreManager())
        }
    }
    
    static var previews: some View {
        Preview()
    }
}
