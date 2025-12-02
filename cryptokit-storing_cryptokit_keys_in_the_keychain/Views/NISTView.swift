/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view for the tab that shows NIST keys.
*/

import SwiftUI

struct NISTView: View {
    @EnvironmentObject var tester: KeyTest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                #if os(iOS)
                Text("Size")
                #endif
                Picker("Size", selection: $tester.nistSize) {
                    ForEach(KeyTest.NISTSize.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            HStack {
                #if os(iOS)
                Text("Purpose")
                #endif
                Picker("Purpose", selection: $tester.purpose) {
                    ForEach(KeyTest.Purpose.allCases, id: \.self) { purpose in
                        Text(purpose.rawValue).tag(purpose)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            if tester.nistSize == .p256 {
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
struct NISTViewPreviews: PreviewProvider {
    static var previews: some View {
        NISTView().environmentObject(KeyTest())
    }
}
#endif
