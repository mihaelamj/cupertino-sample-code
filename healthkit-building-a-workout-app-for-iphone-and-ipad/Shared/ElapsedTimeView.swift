/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows a workout's elapsed time.
*/

import SwiftUI

struct ElapsedTimeView: View {
    var elapsedTime: TimeInterval = 0
    @State private var timeFormatter = ElapsedTimeFormatter()

    var body: some View {
        Text(NSNumber(value: elapsedTime), formatter: timeFormatter)
            .fontWeight(.semibold)
    }
}

class ElapsedTimeFormatter: Formatter {
    let componentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    override func string(for value: Any?) -> String? {
        guard let time = value as? TimeInterval else {
            return nil
        }

        guard let formattedString = componentsFormatter.string(from: time) else {
            return nil
        }

        return formattedString
    }
}

#Preview {
    ElapsedTimeView()
}
