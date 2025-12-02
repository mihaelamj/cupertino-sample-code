/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for the tab that shows the hybrid signature keys.
*/

import SwiftUI

struct HybridSigView: View {
    @EnvironmentObject var tester: KeyTest

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                #if os(iOS)
                Text("Type")
                #endif
                Picker("Type", selection: $tester.hybridsigtype) {
                    ForEach(KeyTest.HybridSigType.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            // The Secure Enclave supports only P256.
            if tester.hybridsigtype == .MLDSA65xP256 {
                Toggle(isOn: $tester.useSecureEnclave) { Text("Use Secure Enclave") }
                    .disabled(tester.disableSecureEnclave)
            }
            ExecutionView()
        }
            .frame(minWidth: 300, idealWidth: 400, maxWidth: 400, alignment: .top)
            .padding(50)
    }
}

#if DEBUG
struct HybridSigViewPreviews: PreviewProvider {
    static var previews: some View {
        HybridSigView().environmentObject(KeyTest())
    }
}
#endif
