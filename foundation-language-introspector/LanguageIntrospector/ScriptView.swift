/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The script name view.
*/

import SwiftUI

struct ScriptView: View {
    let scriptName: String
    
    var body: some View {
        HStack {
            Text("लिपि", comment: "Script")
                .subheadlineTextFormat()
            Spacer()
            Text(scriptName)
                .font(.body)
        }
        .padding(.bottom, 5)
    }
}
