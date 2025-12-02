/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Use the player's calendar to personalize dialog about upcoming events
*/

import EventKit
import FoundationModels

struct CalendarTool: Tool {

    let name = "getCalendarEvents"

    let description: String

    let contactName: String

    init(contactName: String) {
        self.contactName = contactName
        description = """
            Get an event from the player's calendar with \(contactName). \
            Today is \(Date().formatted(date: .complete, time: .omitted))
            """
    }

    @Generable
    struct Arguments {
        let day: Int
        let month: Int
        let year: Int
    }

    func call(arguments: Arguments) async -> String {
        do {
            Logging.general.log("Calling Calendar Tool")
            // Request permission to access calendar events.
            let eventStore = EKEventStore()
            try await eventStore.requestFullAccessToEvents()
            let calendars = eventStore.calendars(for: .event)

            // Build a start and end date from the arguments the model passes.
            let dateComponents = DateComponents(
                year: arguments.year,
                month: arguments.month,
                day: arguments.day
            )
            let startDate = Calendar.current.date(from: dateComponents)!
            let endDate = Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
            let predicate = eventStore.predicateForEvents(
                withStart: startDate,
                end: endDate,
                calendars: calendars
            )

            // Check the Calendar for any events that the person has with
            // the generated NPC.
            let events = eventStore.events(matching: predicate)
            let relevantEvents = events.filter { event in
                event.attendees?.contains(where: { $0.name == contactName }) == true
            }

            if relevantEvents.isEmpty {
                return "The player has \(events.count) events today, but no events with \(contactName)"
            } else {
                return """
                    Events with \(contactName):
                    \((relevantEvents.map { $0.startDate.formatted() + ": " + $0.title }).joined(separator: "\n"))
                    """
            }
        } catch {
            Logging.general.log("Error: \(error)")
            return "Sorry, I can't see your calendar"
        }
    }
}
