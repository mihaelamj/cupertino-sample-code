/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view for the tab that shows symmetric keys.
*/

import SwiftUI

struct SymmetricView: View {
    @EnvironmentObject var tester: KeyTest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                #if os(iOS)
                Text("Size")
                #endif
                Picker("Size", selection: $tester.bits) {
                    ForEach(KeyTest.SymmetricSize.allCases, id: \.self) { size in
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
struct SymmetricViewPreviews: PreviewProvider {
    static var previews: some View {
        SymmetricView().environmentObject(KeyTest())
    }
}
#endif
