/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The data model for date formatter.
*/

import SwiftUI

@MainActor
@Observable class DateFormatterModel {
    /*
        ISO 8601 is a standard that defines date or time formats in a locale-independent manner
        that can be used for technical interchange. It is useful for initializing a specific date or time.
    */
    private let sampleDate: Date
    var formatter: DateFormatter
    
    var dateStyle: DateFormatter.Style
    var timeStyle: DateFormatter.Style
    
    var template: String
    var dateFormat: String
    var selectedPatterns: [String] { didSet { updateFormatter() } }
    
    var localizedDate: String {
        DateFormatter.localizedString(from: sampleDate, dateStyle: dateStyle, timeStyle: timeStyle)
    }
    
    var localizedDateWithPattern: String {
        string(from: sampleDate)
    }
    
    let templateFields = [
        // https://www.unicode.org/reports/tr35/tr35-dates.html#Date_Field_Symbol_Table
        TemplateField(id: 0, title: LocalizedStringKey("काल" /* Era */), patterns: [ "", "GGGGG", "G", "GGGG" ]),
        TemplateField(id: 1, title: LocalizedStringKey("साल" /* Year */), patterns: [ "", "yy", "y" ]),
        TemplateField(id: 2, title: LocalizedStringKey("माह" /* Month */), patterns: [ "", "MMMMM", "M", "MMM", "MMMM" ]),
        TemplateField(id: 3, title: LocalizedStringKey("दिन" /* Day */), patterns: [ "", "d", "dd" ]),
        TemplateField(id: 4, title: LocalizedStringKey("वार" /* Day of Week */), patterns: [ "", "EEEEE", "EEEEEE", "EEE", "EEEE" ]),
        TemplateField(id: 5, title: LocalizedStringKey("घंटा" /* Hour */), patterns: [ "", "j", "jj" ]),
        TemplateField(id: 6, title: LocalizedStringKey("मिनट" /* Minute */), patterns: [ "", "m", "mm" ]),
        TemplateField(id: 7, title: LocalizedStringKey("सेकंड" /* Second */), patterns: [ "", "s", "ss" ])
    ]
    
    init () {
        self.sampleDate = ISO8601DateFormatter().date(from: "2025-06-09T09:41:00-07:00")!
        self.formatter = DateFormatter()
        self.dateStyle = .short
        self.timeStyle = .short
        
        self.template = ""
        self.dateFormat = ""
        self.selectedPatterns = [
            "",
            "y",
            "MMM",
            "d",
            "EEE",
            "j",
            "m",
            ""
        ]
        self.updateFormatter()
    }
    
    func lengthIndicator(length: Int) -> String {
        var result = ""
        for _ in 1...length {
            result += "•"
        }
        return result
    }
    
    private func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    private func updateFormatter() {
        template = selectedPatterns.joined()
        dateFormat = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: Locale.current) ?? ""
        formatter.setLocalizedDateFormatFromTemplate(template)
    }
}

struct TemplateField: Identifiable {
    let id: Int
    let title: LocalizedStringKey
    let patterns: [String]
}
