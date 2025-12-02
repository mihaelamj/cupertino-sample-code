/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to display a date picker and list of drop-in lessons.
*/

import EventKit
import SwiftUI

struct DropInLessonPicker: View {
    @ObservedObject var model: LessonModel
    @State var selection: Lesson?
    
    @State private var selectedEvent: EKEvent?
    @State private var showEventEditViewController = false
    @State private var shouldPresentError: Bool = false
    @State private var alertMessage: String?
    @State private var alertTitle: String?
    @State private var store = EKEventStore()
    
    /*
        When the user selects a date in the picker, the app uses its associated
        day to determine which lesson slots to display. The app offers drop-in
        lessons from Monday through Friday and displays them in a grid with two rows.
     */
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .center) {
                    buildDatePicker()
                    Spacer()
                    /*
                        The selected day lessons array is empty when the app
                        fails loading the lesson data or when the user selects a
                        Saturday and Sunday date from the date picker.
                    */
                    if model.selectedDayLessons.isEmpty {
                        MessageView(message: .lessonSlots)
                        Spacer()
                    } else {
                        selectTimeSlot()
                        Grid(alignment: .center, horizontalSpacing: 30, verticalSpacing: 30) {
                            GridRow {
                                ForEach(model.selectedDayLessons[..<lowerLimit], id: \.self) { lesson in
                                    DropInLesson(lesson: lesson, selection: $selection)
                                }
                            }
                            GridRow {
                                ForEach(model.selectedDayLessons[lowerLimit...], id: \.self) { lesson in
                                    DropInLesson(lesson: lesson, selection: $selection)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Drop-in lessons")
            buildBookingButton()
        }
        .alertErrorMessage(message: alertMessage, title: alertTitle, isPresented: $shouldPresentError)
    }
 
    /// Each grid row contains three lesson slots.
    var lowerLimit: Int {
        (model.selectedDayLessons.count) / 2
    }
    
    /*
        The system calls this when the user dismiss the event edit view
        controller. The app disables the booking button and unselects the current
        lesson time slot.
    */
    func didDismissEventEditController() {
        selection = nil
    }
    
    /*
        The app updates its UI with a list of lesson time slots for the selected
        day.
    */
    func refreshLessonsAction() {
        model.updateSelectedDayLessons()
        selection = nil
    }
    
    /*
        The system calls this when the user taps the booking button.
        The app creates an event with the details of the currently selected
        lesson.
     */
    func bookLessonAction() {
        Task {
            if #unavailable(iOS 17) {
                do {
                    guard try await store.requestAccess(to: .event) else {
                        selection = nil
                        let message = "The app doesn't have permission to access calendar data. Please grant the app access to Calendar in Settings."
                        showError(message, title: "Calendar access denied")
                        return
                    }
                } catch {
                    selection = nil
                    showError(error.localizedDescription, title: "Failed to request calendar access")
                    return
                }
            }
            
            if let selection = selection {
               selectedEvent = selection.eventWithDate(model.selectedDate, store: store)
            }
            
            showEventEditViewController.toggle()
        }
    }
    
    @ViewBuilder
    func selectTimeSlot() -> some View {
        VStack {
            Text("Select a time slot")
                .font(.headline)
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Divider()
            .frame(height: 2)
        }
        .padding()
    }
    
    @ViewBuilder
    /// Set up the date picker.
    private func buildDatePicker() -> some View {
        if #available(iOS 17.0, *) {
            DatePickerView(displayDate: $model.selectedDate)
            .onChange(of: model.selectedDate, refreshLessonsAction)
        } else {
            // Fall back on earlier versions.
            DatePickerView(displayDate: $model.selectedDate)
            .onChange(of: model.selectedDate) { newvalue in
                refreshLessonsAction()
            }
        }
    }
    
    @ViewBuilder
    /*
        The DropIn lessons app creates and saves events, which doesn't require
        accessing calendar data. Thus, the app has no need for prompting the
        user for Calendar authorization. The app presents the event edit view
        controller when the user taps the booking button. The controller takes
        an event created from the currently selected lesson and an event store
        as parameters. EKEventEditViewController objects render their content
        out-of-process. These controllers allow apps to present an editor for
        adding, editing, and deleting events without prompting the user for
        access. The editor also displays all the user's calendars.
     */
    private func buildBookingButton() -> some View {
        if !model.selectedDayLessons.isEmpty {
            BookingButton(selection: $selection, action: bookLessonAction)
                .sheet(isPresented: $showEventEditViewController,
                       onDismiss: didDismissEventEditController, content: {
                   EventEditViewController(event: $selectedEvent, eventStore: store)
            })
        }
    }
    
    func showError(_ message: String, title: String) {
        alertTitle = title
        alertMessage = message
        shouldPresentError = true
    }
}

struct DropInLessonPicker_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject private var model = LessonModel(date: Date())
        
        var body: some View {
            DropInLessonPicker(model: LessonModel(date: Date()))
        }
    }
    static var previews: some View {
        Preview()
    }
}
