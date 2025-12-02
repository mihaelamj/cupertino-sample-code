/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The observable view model that drives the UI, and interfaces with AlarmKit.
*/

import AlarmKit
import SwiftUI
import AppIntents

@Observable class ViewModel {
    typealias AlarmConfiguration = AlarmManager.AlarmConfiguration<CookingData>
    typealias AlarmsMap = [UUID: (Alarm, LocalizedStringResource)]
    
    @MainActor var alarmsMap = AlarmsMap()
    @ObservationIgnored private let alarmManager = AlarmManager.shared
    
    @MainActor var hasUpcomingAlerts: Bool {
        !alarmsMap.isEmpty
    }
    
    init() {
        observeAlarms()
    }
    
    func fetchAlarms() {
        do {
            let remoteAlarms = try alarmManager.alarms
            updateAlarmState(with: remoteAlarms)
        } catch {
            print("Error fetching alarms: \(error)")
        }
    }
    
    func scheduleAlarm(with userInput: AlarmForm) {
        let attributes = AlarmAttributes(presentation: alarmPresentation(with: userInput),
                                         metadata: CookingData(),
                                         tintColor: Color.accentColor)
        
        let id = UUID()
        let alarmConfiguration = AlarmConfiguration(countdownDuration: userInput.countdownDuration,
                                                    schedule: userInput.schedule,
                                                    attributes: attributes,
                                                    stopIntent: StopIntent(alarmID: id.uuidString),
                                                    secondaryIntent: secondaryIntent(alarmID: id, userInput: userInput))
        
        scheduleAlarm(id: id, label: userInput.localizedLabel, alarmConfiguration: alarmConfiguration)
    }
    
    // Schedules an alarm with an alert only.
    func scheduleAlertOnlyExample() {
        let alertContent = AlarmPresentation.Alert(title: "Wake Up", stopButton: .stopButton)
        
        let attributes = AlarmAttributes<CookingData>(presentation: AlarmPresentation(alert: alertContent),
                                                      tintColor: Color.accentColor)
        
        let alarmConfiguration = AlarmConfiguration(schedule: .twoMinsFromNow, attributes: attributes)
        
        scheduleAlarm(id: UUID(), label: "Wake Up", alarmConfiguration: alarmConfiguration)
    }
    
    // Schedules an alarm with countdown button.
    func scheduleCountdownAlertExample() {
        let alertContent = AlarmPresentation.Alert(title: "Food Ready",
                                                   stopButton: .stopButton,
                                                   secondaryButton: .repeatButton,
                                                   secondaryButtonBehavior: .countdown)
        
        let countdownContent = AlarmPresentation.Countdown(title: "Cooking", pauseButton: .pauseButton)
        
        let pausedContent = AlarmPresentation.Paused(title: "Paused", resumeButton: .resumeButton)
        
        let attributes = AlarmAttributes(presentation: AlarmPresentation(alert: alertContent, countdown: countdownContent, paused: pausedContent),
                                         metadata: CookingData(method: .oven),
                                         tintColor: Color.accentColor)
        
        let id = UUID()
        let alarmConfiguration = AlarmConfiguration(countdownDuration: .init(preAlert: 15 * 60, postAlert: 15 * 60),
                                                    attributes: attributes,
                                                    secondaryIntent: RepeatIntent(alarmID: id.uuidString))
        
        scheduleAlarm(id: UUID(), label: "Food is cooking", alarmConfiguration: alarmConfiguration)
    }
    
    // Schedules an alarm with a custom button to launch the app.
    func scheduleCustomButtonAlertExample() {
        let alertContent = AlarmPresentation.Alert(title: "Wake Up",
                                                   stopButton: .stopButton,
                                                   secondaryButton: .openAppButton,
                                                   secondaryButtonBehavior: .custom)
        
        let attributes = AlarmAttributes<CookingData>(presentation: AlarmPresentation(alert: alertContent),
                                                      tintColor: Color.accentColor)
        
        let id = UUID()
        let alarmConfiguration = AlarmConfiguration(schedule: .twoMinsFromNow,
                                                    attributes: attributes,
                                                    stopIntent: StopIntent(alarmID: id.uuidString),
                                                    secondaryIntent: OpenAlarmAppIntent(alarmID: id.uuidString))
        
        scheduleAlarm(id: id, label: "Wake Up", alarmConfiguration: alarmConfiguration)
    }
    
    func scheduleAlarm(id: UUID, label: LocalizedStringResource, alarmConfiguration: AlarmConfiguration) {
        Task {
            do {
                guard await requestAuthorization() else {
                    print("Not authorized to schedule alarms.")
                    return
                }
                let alarm = try await alarmManager.schedule(id: id, configuration: alarmConfiguration)
                await MainActor.run {
                    alarmsMap[id] = (alarm, label)
                }
            } catch {
                print("Error encountered when scheduling alarm: \(error)")
            }
        }
    }
    
    func unscheduleAlarm(with alarmID: UUID) {
        try? alarmManager.cancel(id: alarmID)
        Task { @MainActor in
            alarmsMap[alarmID] = nil
        }
    }
    
    private func alarmPresentation(with userInput: AlarmForm) -> AlarmPresentation {
        let secondaryButtonBehavior = userInput.secondaryButtonBehavior
        let secondaryButton: AlarmButton? = switch secondaryButtonBehavior {
            case .countdown: .repeatButton
            case .custom: .openAppButton
            default: nil
        }
        
        let alertContent = AlarmPresentation.Alert(title: userInput.localizedLabel,
                                                   stopButton: .stopButton,
                                                   secondaryButton: secondaryButton,
                                                   secondaryButtonBehavior: secondaryButtonBehavior)

        guard userInput.countdownDuration != nil else {
            // An alarm without a countdown only specifies an alert state.
            return AlarmPresentation(alert: alertContent)
        }
        
        // With countdown enabled, a presentation appears for both a countdown and paused state.
        let countdownContent = AlarmPresentation.Countdown(title: userInput.localizedLabel,
                                                           pauseButton: .pauseButton)
        
        let pausedContent = AlarmPresentation.Paused(title: "Paused",
                                                     resumeButton: .resumeButton)
        
        return AlarmPresentation(alert: alertContent, countdown: countdownContent, paused: pausedContent)
    }
    
    private func secondaryIntent(alarmID: UUID, userInput: AlarmForm) -> (any LiveActivityIntent)? {
        guard let behavior = userInput.secondaryButtonBehavior else { return nil }
        
        switch behavior {
        case .countdown:
            return RepeatIntent(alarmID: alarmID.uuidString)
        case .custom:
            return OpenAlarmAppIntent(alarmID: alarmID.uuidString)
        @unknown default:
            return nil
        }
    }
    
    private func observeAlarms() {
        Task {
            for await incomingAlarms in alarmManager.alarmUpdates {
                updateAlarmState(with: incomingAlarms)
            }
        }
    }
    
    private func updateAlarmState(with remoteAlarms: [Alarm]) {
        Task { @MainActor in
            
            // Update existing alarm states.
            remoteAlarms.forEach { updated in
                alarmsMap[updated.id, default: (updated, "Alarm (Old Session)")].0 = updated
            }
            
            let knownAlarmIDs = Set(alarmsMap.keys)
            let incomingAlarmIDs = Set(remoteAlarms.map(\.id))
            
            // Clean-up removed alarms.
            let removedAlarmIDs = Set(knownAlarmIDs.subtracting(incomingAlarmIDs))
            removedAlarmIDs.forEach {
                alarmsMap[$0] = nil
            }
        }
    }
    
    private func requestAuthorization() async -> Bool {
        switch alarmManager.authorizationState {
        case .notDetermined:
            do {
                let state = try await alarmManager.requestAuthorization()
                return state == .authorized
            } catch {
                print("Error occurred while requesting authorization: \(error)")
                return false
            }
        case .denied: return false
        case .authorized: return true
        @unknown default: return false
        }
    }
}

extension AlarmButton {
    static var openAppButton: Self {
        AlarmButton(text: "Open", textColor: .black, systemImageName: "swift")
    }
    
    static var pauseButton: Self {
        AlarmButton(text: "Pause", textColor: .black, systemImageName: "pause.fill")
    }
    
    static var resumeButton: Self {
        AlarmButton(text: "Start", textColor: .black, systemImageName: "play.fill")
    }
    
    static var repeatButton: Self {
        AlarmButton(text: "Repeat", textColor: .black, systemImageName: "repeat.circle")
    }
    
    static var stopButton: Self {
        AlarmButton(text: "Done", textColor: .white, systemImageName: "stop.circle")
    }
}

extension Alarm {
    var alertingTime: Date? {
        guard let schedule else { return nil }
        
        switch schedule {
        case .fixed(let date):
            return date
        case .relative(let relative):
            var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
            components.hour = relative.time.hour
            components.minute = relative.time.minute
            return Calendar.current.date(from: components)
        @unknown default:
            return nil
        }
    }
}

extension Alarm.Schedule {
    static var twoMinsFromNow: Self {
        let twoMinsFromNow = Date.now.addingTimeInterval(2 * 60)
        let time = Alarm.Schedule.Relative.Time(hour: Calendar.current.component(.hour, from: twoMinsFromNow),
                                                minute: Calendar.current.component(.minute, from: twoMinsFromNow))
        return .relative(.init(time: time))
    }
}

extension TimeInterval {
    func customFormatted() -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: self) ?? self.formatted()
    }
}

extension Locale {
    var orderedWeekdays: [Locale.Weekday] {
        let days: [Locale.Weekday] = [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        if let firstDayIdx = days.firstIndex(of: firstDayOfWeek), firstDayIdx != 0 {
            return Array(days[firstDayIdx...] + days[0..<firstDayIdx])
        }
        return days
    }
}
