/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view for displaying log text.
*/

import SwiftUI

struct LogView: View {
    
    @ObservedObject var logModel: LogModel

    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button() {
                    logModel.clear()
                } label: {
                    Text("Clear")
                        .frame(alignment: .leading)
                }
                .padding(.leading)
            }
            .padding(.vertical, UIConstants.defaultMargin)

            ScrollView {
                ScrollViewReader { value in
                    Text(logModel.logData)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .id(0)
                    .onChange(of: logModel.logData) { newValue in
                        value.scrollTo(0, anchor: .bottom)
                    }
                }

            }
            .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
            .background(UIConstants.backgroundColor)
            .cornerRadius(UIConstants.defaultCornerRadius)
        }
    }
    
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView(logModel: LogModel(logData: "Log data a\nLog data b\nLog data c\n"))
    }
}
