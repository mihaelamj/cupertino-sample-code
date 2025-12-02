/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structure containing the alarm configuration a person provides using the form.
*/

import AlarmKit

struct AlarmForm {
    var label = ""
    
    var selectedDate = Date.now
    var selectedDays = Set<Locale.Weekday>()
    
    var selectedPreAlert = CountdownInterval()
    var selectedPostAlert = CountdownInterval()
    
    var selectedSecondaryButton: SecondaryButtonOption = .none
    
    var preAlertEnabled = false
    var scheduleEnabled = false
    
    var isValidAlarm: Bool {
        (preAlertEnabled && selectedPreAlert.interval > 0) || scheduleEnabled
    }
    
    var localizedLabel: LocalizedStringResource {
        label.isEmpty ? LocalizedStringResource("Alarm") : LocalizedStringResource(stringLiteral: label)
    }
    
    func isSelected(day: Locale.Weekday) -> Bool {
        selectedDays.contains(day)
    }
    
    enum SecondaryButtonOption: String, CaseIterable {
        case none = "None"
        case countdown = "Countdown"
        case openApp = "Open App"
    }
    
    struct CountdownInterval {
        var hour = 0
        var min = 15
        var sec = 0
        
        var interval: TimeInterval {
            TimeInterval(hour * 60 * 60 + min * 60 + sec)
        }
    }
    
    // MARK: AlarmKit Properties
    
    var countdownDuration: Alarm.CountdownDuration? {
        let preAlertCountdown: TimeInterval? = if preAlertEnabled {
            selectedPreAlert.interval
        } else { nil }
        
        let postAlertCountdown: TimeInterval? =  if secondaryButtonBehavior == .countdown {
            selectedPostAlert.interval
        } else { nil }
        
        guard preAlertCountdown != nil || postAlertCountdown != nil else { return nil }
        
        return .init(preAlert: preAlertCountdown, postAlert: postAlertCountdown)
    }
    
    var schedule: Alarm.Schedule? {
        guard scheduleEnabled else { return nil }
        
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: selectedDate)
        
        guard let hour = dateComponents.hour, let minute = dateComponents.minute else { return nil }
        
        let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
        return .relative(.init(
            time: time,
            repeats: selectedDays.isEmpty ? .never : .weekly(Array(selectedDays))
        ))
    }
    
    var secondaryButtonBehavior: AlarmPresentation.Alert.SecondaryButtonBehavior? {
        switch selectedSecondaryButton {
        case .none: nil
        case .countdown: .countdown
        case .openApp: .custom
        }
    }
}
