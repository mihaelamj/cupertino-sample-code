/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Information and controls to display at the bottom of the sidebar.
*/

import SwiftUI

/// Information and controls to display at the bottom of the sidebar.
struct QuakeListInfo: View {
    @Environment(ViewModel.self) private var viewModel

    var count: Int = 0

    var body: some View {
        @Bindable var viewModel = viewModel

        HStack {
            VStack {
                Text("\(count) earthquakes")
                Text("\(viewModel.totalQuakes) total")
                    .foregroundStyle(.secondary)
            }
            .fixedSize()
            Spacer()
            DatePicker(
                "Search Date",
                selection: $viewModel.searchDate,
                in: viewModel.searchDateRange,
                displayedComponents: .date
            )
            .labelsHidden()
            .disabled(viewModel.totalQuakes == 0)
        }
    }
}

#Preview {
    QuakeListInfo(count: 8)
        .environment(ViewModel.preview)
}
