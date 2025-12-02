/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI view for the step count cell.
*/

import SwiftUI

struct StepData: Identifiable {
    let id: UUID
    var date: Date
    var stepCount: Int
}

struct StepCountCellView: View {
    var data: StepData
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(data.date, format: .dateTime.weekday())
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .font(.system(.title3, weight: .bold).uppercaseSmallCaps())
                .frame(minWidth: 50)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(data.stepCount, format: .number)
                    .foregroundStyle(.primary)
                    .font(.system(.title, weight: .semibold))
                    .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
                Text("steps")
                    .foregroundStyle(.orange)
                    .font(.system(.subheadline, weight: .bold))
            }
            Spacer()
        }
    }
}

extension StepData {
    static func generateRandomData(days: Int) -> [StepData] {
        var data = [StepData]()
        let today = Date()
        for index in 0..<days {
            let date = Calendar.current.date(byAdding: .day, value: -index, to: today)!
            let stepCount = Int.random(in: 500...25_000)
            data.append(StepData(id: UUID(), date: date, stepCount: stepCount))
        }
        return data
    }
}

struct StepCountCellView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            ForEach(StepData.generateRandomData(days: 7)) { data in
                StepCountCellView(data: data)
            }
        }
    }
}
