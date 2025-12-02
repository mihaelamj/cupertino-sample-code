/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A button on a symptom event that indicates its logged status.
*/

import SwiftUI

struct SymtomLogButton: View {
    let isSymptomLogged: Bool

    var loggedStateSymbolName: String {
        isSymptomLogged ? "checkmark.circle.fill" : "circle"
    }

    var symbolColor: Color {
        isSymptomLogged ? .green : .secondary
    }

    var body: some View {
        Image(systemName: loggedStateSymbolName)
            .animation(.easeInOut(duration: 0.25), value: isSymptomLogged)
            .font(.title2)
            .foregroundStyle(symbolColor)
    }
}
