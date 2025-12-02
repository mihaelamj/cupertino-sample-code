/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for the tab that shows the ML-KEM keys.
*/

import SwiftUI

struct MLKEMView: View {
    @EnvironmentObject var tester: KeyTest

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                #if os(iOS)
                Text("Type")
                #endif
                Picker("Type", selection: $tester.mlkemtype) {
                    ForEach(KeyTest.MLKEMType.allCases, id: \.self) { size in
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
struct MLKEMViewPreviews: PreviewProvider {
    static var previews: some View {
        MLKEMView().environmentObject(KeyTest())
    }
}
#endif
