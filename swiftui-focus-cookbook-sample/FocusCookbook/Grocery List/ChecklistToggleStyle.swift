/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A toggle style that appears as a dashed gray circle symbol when toggled off and a
 green checkmark symbol when toggled on.
*/

import SwiftUI

struct ChecklistToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(configuration.isOn ? .green : .gray)
                .font(.system(size: 20))
                .contentTransition(.symbolEffect)
                .animation(.linear, value: configuration.isOn)
        }
        .buttonStyle(.plain)
        .contentShape(.circle)
    }
}

extension ToggleStyle where Self == ChecklistToggleStyle {
    static var checklist: ChecklistToggleStyle { .init() }
}
