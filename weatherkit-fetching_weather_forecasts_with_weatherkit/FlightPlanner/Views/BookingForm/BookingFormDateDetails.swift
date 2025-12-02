/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The date details on the booking form for selecting the user's departure and
arrival (or return) dates.
*/

import SwiftUI

struct BookingFormDateDetails: View {
    @Binding var inputData: BookingFormInputData
    
    var body: some View {
        HStack {
            DepartureDatePicker(inputData: $inputData)
                .onChange(of: inputData.departureDate) { newValue in
                    if inputData.arrivalDate < newValue {
                        inputData.arrivalDate = newValue
                    }
                }
            if inputData.journey != .oneWay {
                Color.clear
                    .frame(maxWidth: 44, maxHeight: 44)
                    .padding()
                ReturnDatePicker(inputData: $inputData)
            }
        }
        .datePickerStyle(.compact)
        .padding(.vertical)
    }
}

private struct DepartureDatePicker: View {
    @Binding var selection: Date
    var journey: FlightJourney
    @Environment(\.calendar) private var calendar
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Departure")
                .font(.caption)
            if journey == .oneWay {
                datePicker.datePickerStyle(.graphical)
            } else {
                datePicker
            }
        }
    }
    
    var datePicker: some View {
        DatePicker(
            selection: $selection,
            in: range,
            displayedComponents: .date
        ) {
            Label("Departure date", systemImage: "calendar")
        }
    }
    
    var range: ClosedRange<Date> {
        .now ... max
    }
    
    var max: Date {
        let dateComponents = DateComponents(month: 6)
        let max = calendar.date(byAdding: dateComponents, to: .now)
        return max ?? .now
    }
}

extension DepartureDatePicker {
    @MainActor
    init(inputData: Binding<BookingFormInputData>) {
        self.init(
            selection: inputData.departureDate,
            journey: inputData.wrappedValue.journey)
    }
}

private struct ReturnDatePicker: View {
    @Binding var selection: Date
    var departureDate: Date
    var journey: FlightJourney
    @Environment(\.calendar) private var calendar
    
    var body: some View {
        VStack(alignment: .trailing) {
            Text("Return")
                .font(.caption)
            DatePicker(selection: $selection,
                in: range,
                displayedComponents: .date
            ) {
                Label("Return date", systemImage: "calendar")
            }
        }
    }
    
    var range: ClosedRange<Date> {
        departureDate ... max
    }
    
    var max: Date {
        let dateComponents = DateComponents(month: 6)
        let max = calendar.date(byAdding: dateComponents, to: departureDate)
        return max ?? .now
    }
}

extension ReturnDatePicker {
    @MainActor
    init(inputData: Binding<BookingFormInputData>) {
        self.init(
            selection: inputData.arrivalDate,
            departureDate: inputData.wrappedValue.departureDate,
            journey: inputData.wrappedValue.journey)
    }
}

struct BookingFormDateDetails_Previews: PreviewProvider {
    static var previews: some View {
        BookingFormDateDetails(inputData: .constant(BookingFormInputData()))
    }
}
