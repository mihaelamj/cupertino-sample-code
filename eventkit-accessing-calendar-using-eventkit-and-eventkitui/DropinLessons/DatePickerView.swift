/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A date picker view from which you can use to select a date within a month.
*/

import SwiftUI

struct DatePickerView: View {
    @Binding var displayDate: Date
    
    let dateRange: ClosedRange<Date> = {
        let now = Date.now
        return now...Calendar.current.date(byAdding: .month, value: 1, to: now)!
    }()
    
    var body: some View {
        DatePicker(
                "Start Date",
                selection: $displayDate,
                in: dateRange,
                displayedComponents: [.date]
        )
        .labelsHidden()
        .datePickerStyle(.graphical)
    }
}

struct DatePickerView_Previews: PreviewProvider {
    static var previews: some View {
        DatePickerView(displayDate: .constant(Date()))
    }
}
