/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for the tab that shows the ML-DSA keys.
*/

import SwiftUI

struct MLDSAView: View {
    @EnvironmentObject var tester: KeyTest

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                #if os(iOS)
                Text("Type")
                #endif
                Picker("Type", selection: $tester.mldsatype) {
                    ForEach(KeyTest.MLDSAType.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            Toggle(isOn: $tester.useSecureEnclave) { Text("Use Secure Enclave") }
                .disabled(tester.disableSecureEnclave)
            ExecutionView()
        }
            .frame(minWidth: 300, idealWidth: 400, maxWidth: 400, alignment: .top)
            .padding(50)
    }
}

#if DEBUG
struct MLDSAViewPreviews: PreviewProvider {
    static var previews: some View {
        MLDSAView().environmentObject(KeyTest())
    }
}
#endif
