/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
SwiftUI Views that the app uses.
*/

import AlarmKit
import SwiftUI

struct ContentView: View {
    @State private var viewModel = ViewModel()
    @State private var showAddSheet = false
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Alarms")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    menuButton
                }
        }
        .sheet(isPresented: $showAddSheet) {
            AlarmAddView()
        }
        .environment(viewModel)
        .onAppear {
            viewModel.fetchAlarms()
        }
        .tint(.accentColor)
    }
    
    var menuButton: some View {
        Menu {
            // Schedules an alarm with an alert but no additional configuration.
            Button {
                viewModel.scheduleAlertOnlyExample()
            } label: {
                Label("Alert only", systemImage: "bell.circle.fill")
            }
            
            // Schedules an alarm with a countdown button.
            Button {
                viewModel.scheduleCountdownAlertExample()
            } label: {
                Label("With Countdown", systemImage: "fitness.timer.fill")
            }
            
            // Schedules an alarm with a custom button to launch the app.
            Button {
                viewModel.scheduleCustomButtonAlertExample()
            } label: {
                Label("With Custom Button", systemImage: "alarm")
            }
            
            // Displays a sheet with configuration options for a new alarm.
            Button {
                showAddSheet.toggle()
            } label: {
                Label("Configure", systemImage: "pencil.and.scribble")
            }
        } label: {
            Image(systemName: "plus")
        }
    }
    
    @ViewBuilder var content: some View {
        if viewModel.hasUpcomingAlerts {
            alarmList(alarms: Array(viewModel.alarmsMap.values))
        } else {
            ContentUnavailableView("No Alarms", systemImage: "clock.badge.exclamationmark", description: Text("Add a new alarm by tapping + button."))
        }
    }
    
    func alarmList(alarms: [ViewModel.AlarmsMap.Value]) -> some View {
        List {
            ForEach(alarms, id: \.0.id) { (alarm, label) in
                AlarmCell(alarm: alarm, label: label)
            }
            .onDelete { indexSet in
                indexSet.forEach { idx in
                    viewModel.unscheduleAlarm(with: alarms[idx].0.id)
                }
            }
        }
    }
}

struct AlarmCell: View {
    var alarm: Alarm
    var label: LocalizedStringResource
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let alertingTime = alarm.alertingTime {
                    Text(alertingTime, style: .time)
                        .font(.title)
                        .fontWeight(.medium)
                } else if let countdown = alarm.countdownDuration?.preAlert {
                    Text(countdown.customFormatted())
                        .font(.title)
                        .fontWeight(.medium)
                }
                Spacer()
                tag
            }
            
            Text(label)
                .font(.headline)
        }
    }
    
    var tag: some View {
        Text(tagLabel)
            .textCase(.uppercase)
            .font(.caption.bold())
            .padding(4)
            .background(tagColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    var tagLabel: String {
        switch alarm.state {
        case .scheduled: "Scheduled"
        case .countdown: "Running"
        case .paused: "Paused"
        case .alerting: "Alert"
        @unknown default: "!"
        }
    }
    
    var tagColor: Color {
        switch alarm.state {
        case .scheduled: .blue
        case .countdown: .green
        case .paused: .yellow
        case .alerting: .red
        @unknown default: .gray
        }
    }
}

struct AlarmAddView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ViewModel.self) private var viewModel
    
    @State private var userInput = AlarmForm()
    
    var body: some View {
        NavigationStack {
            Form {
                textfield
                countdownSection
                scheduleSection
                secondaryButtonSection
            }
            .navigationTitle("Add Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.scheduleAlarm(with: userInput)
                        dismiss()
                    } label: {
                        Text("Add")
                    }
                    .disabled(!userInput.isValidAlarm)
                }
            }
        }
    }
    
    var textfield: some View {
        Label(title: {
            TextField("Label", text: $userInput.label)
        }, icon: {
            Image(systemName: "character.cursor.ibeam")
        })
    }
    
    var countdownSection: some View {
        VStack {
            Toggle("Countdown (Pre-Alert)", systemImage: "timer", isOn: $userInput.preAlertEnabled)
            if userInput.preAlertEnabled {
                TimePickerView(hour: $userInput.selectedPreAlert.hour, min: $userInput.selectedPreAlert.min, sec: $userInput.selectedPreAlert.sec)
            }
        }
    }
    
    var scheduleSection: some View {
        VStack {
            Toggle("Schedule", systemImage: "calendar", isOn: $userInput.scheduleEnabled)
            if userInput.scheduleEnabled {
                DatePicker("", selection: $userInput.selectedDate, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                
                daysOfTheWeekSection
            }
        }
    }
    
    var daysOfTheWeekSection: some View {
        HStack(spacing: -3) {
            ForEach(Locale.autoupdatingCurrent.orderedWeekdays, id: \.self) { weekday in
                Button(action: {
                    if userInput.isSelected(day: weekday) {
                        userInput.selectedDays.remove(weekday)
                    } else {
                        userInput.selectedDays.insert(weekday)
                    }
                }) {
                    Text(weekday.rawValue.localizedUppercase)
                        .font(.caption2)
                        .allowsTightening(true)
                        .minimumScaleFactor(0.5)
                        .frame(width: 26, height: 26)
                }
                .tint(.accent.opacity(userInput.isSelected(day: weekday) ? 1 : 0.4))
                .buttonBorderShape(.circle)
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    var secondaryButtonSection: some View {
        VStack {
            Picker("Secondary Button", systemImage: "button.programmable", selection: $userInput.selectedSecondaryButton) {
                ForEach(AlarmForm.SecondaryButtonOption.allCases, id: \.self) { button in
                    Text(button.rawValue).tag(button)
                }
            }
            
            if userInput.selectedSecondaryButton == .countdown {
                TimePickerView(hour: $userInput.selectedPostAlert.hour, min: $userInput.selectedPostAlert.min, sec: $userInput.selectedPostAlert.sec)
            }
            
            let callout = switch userInput.selectedSecondaryButton {
            case .none: "Only the Stop button is displayed in the alarm alert."
            case .countdown: "Displays the Repeat option when the alarm is triggered."
            case .openApp: "Displays the Open App button when the alarm is triggered."
            }
            
            Text(callout)
                .font(.callout)
                .fontWeight(.light)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
                .padding(.vertical, 4)
        }
    }
}

struct TimePickerView: View {
    @Binding var hour: Int
    @Binding var min: Int
    @Binding var sec: Int
    
    private let labelOffset = 40.0
    
    var body: some View {
        HStack(spacing: 0) {
            pickerRow(title: "hr", range: 0..<24, selection: $hour)
            pickerRow(title: "min", range: 0..<60, selection: $min)
            pickerRow(title: "sec", range: 0..<60, selection: $sec)
        }
    }
    
    func pickerRow(title: String, range: Range<Int>, selection: Binding<Int>) -> some View {
        Picker("", selection: selection) {
            ForEach(range, id: \.self) {
                Text("\($0)")
            }
            .background(.clear)
        }
        .pickerStyle(.wheel)
        .tint(.white)
        .overlay {
            Text(title)
                .font(.caption)
                .frame(width: labelOffset, alignment: .leading)
                .offset(x: labelOffset)
        }
    }
}

#Preview {
    ContentView()
}
