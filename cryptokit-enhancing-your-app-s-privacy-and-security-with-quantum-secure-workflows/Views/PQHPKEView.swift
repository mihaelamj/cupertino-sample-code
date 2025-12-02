/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for the tab that shows the PQ-HPKE keys.
*/

import SwiftUI

struct PQHPKEView: View {
    @EnvironmentObject var tester: KeyTest

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                #if os(iOS)
                Text("Type")
                #endif
                Picker("Type", selection: $tester.pqhpketype) {
                    ForEach(KeyTest.PQHPKEType.allCases, id: \.self) { size in
                        Text(size.rawValue).tag(size)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            ExecutionView()
        }
            .frame(minWidth: 300, idealWidth: 400, maxWidth: 400, alignment: .top)
            .padding(50)
    }
}

#if DEBUG
struct PQHPKEViewPreviews: PreviewProvider {
    static var previews: some View {
        PQHPKEView().environmentObject(KeyTest())
    }
}
#endif
