/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The execution view, common to all key types.
*/

import SwiftUI

struct ExecutionView: View {
    @EnvironmentObject var tester: KeyTest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack {
                if tester.status == .pending {
                    Button("Test", action: tester.run)
                } else {
                    Button("Reset", action: tester.reset)
                }
                Spacer()
                Rectangle()
                    .frame(width: 60, height: 30)
                    .cornerRadius(5)
                    .foregroundColor(tester.status == .fail ? .red : (tester.status == .pending ? .clear : .green))
                    .overlay(Text(tester.status.rawValue)
                        .font(Font.body.bold())
                        .foregroundColor(.white)
                    )
            }
            Text(tester.message)
                .lineLimit(20)
            Spacer()
        }
    }
}
