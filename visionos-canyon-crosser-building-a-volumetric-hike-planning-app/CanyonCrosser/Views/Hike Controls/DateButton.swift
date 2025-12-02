/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A button view to show a date picker.
*/

import SwiftUI

struct DateButton: View {
    @Environment(AppModel.self) var appModel

    let title: String
    @Binding var date: Date

    @State var showDatePicker: Bool = false

    var body: some View {
        Button {
            showDatePicker.toggle()
            if showDatePicker {
                appModel.hikePlaybackStateComponent.isPaused = true
            }
        } label: {
            DateLabel(time: date, title: title)
        }
        .popover(isPresented: $showDatePicker) {
            DatePicker(selection: $date, displayedComponents: [.hourAndMinute]) {
                Text(title)
            }
            .datePickerStyle(.wheel)
            .frame(width: 250, height: 200)
        }
        .buttonBorderShape(.roundedRectangle(radius: 16))
    }
}

#Preview("DateButton", traits: .modifier(HikerComponentAppModelData())) {
    @Previewable @State var date: Date = .distantPast

    DateButton(
        title: "Date Button",
        date: $date
    )
    .padding()
    .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 26))
}

/// A view that displays a title and a time, with an icon that changes based on the time of day.
private struct DateLabel: View {
    let time: Date
    let title: String

    var body: some View {
        VStack {
            HStack {
                Image(systemName: systemName)
                    .foregroundColor(imageColor)

                Text(time.formatted(date: .omitted, time: .shortened))
                    .font(.headline)
                    .fontWeight(.bold)
            }
            Text(title.uppercased())
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding([.leading, .trailing])
    }
}

extension DateLabel {
    /// The name of the SF Symbol, depending on the time of day.
    var systemName: String {
        switch time.hour() {
        case 0..<6: return "moon.fill"
        case 6..<10: return "sun.horizon.fill"
        case 10..<19: return "sun.max.fill"
        case 19..<21: return "sun.horizon.fill"
        case 21..<24: return "moon.fill"
        default: return "sun.fill"
        }
    }

    /// The color of the SF Symbol, depending on the time of day.
    var imageColor: Color {
        switch time.hour() {
        case 0..<6: return .blue
        case 6..<21: return .yellow
        case 21..<24: return .blue
        default: return .gray
        }
    }
}

#Preview("Date Labels") {
    let fourHours: TimeInterval = 60 * 60 * 4

    VStack(spacing: 20) {
        DateLabel(time: .init(timeIntervalSince1970: fourHours * 2), title: "Midnight")
        DateLabel(time: .init(timeIntervalSince1970: fourHours * 3), title: "Early Morning")
        DateLabel(time: .init(timeIntervalSince1970: fourHours * 4), title: "Morning")
        DateLabel(time: .init(timeIntervalSince1970: fourHours * 5), title: "Noon")
        DateLabel(time: .init(timeIntervalSince1970: fourHours * 6), title: "Afternoon")
        DateLabel(time: .init(timeIntervalSince1970: fourHours), title: "Sunset")
        DateLabel(time: .init(timeIntervalSince1970: fourHours * 1.5), title: "Night")
    }
    .padding()
    .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 20))
}
