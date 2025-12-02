/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view for the tab that shows Curve keys.
*/

import SwiftUI

struct CurveView: View {
    @EnvironmentObject var tester: KeyTest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
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
            ExecutionView()
        }
            .frame(minWidth: 300, idealWidth: 400, maxWidth: 400, alignment: .top)
            .padding(50)
    }
}

#if DEBUG
struct CurveViewPreviews: PreviewProvider {
    static var previews: some View {
        CurveView().environmentObject(KeyTest())
    }
}
#endif
