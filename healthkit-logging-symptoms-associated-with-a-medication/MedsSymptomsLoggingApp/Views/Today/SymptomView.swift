/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays associated symptoms for a particular dose.
*/

import SwiftUI

struct SymptomView: View {

    @Binding var symptomModel: SymptomModel
    @State private var isShowingPicker: Bool = false
    @State private var isSymptomLogged: Bool = false

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.blue)
                .opacity(isSymptomLogged ? 0.30 : 0.90)
                .cornerRadius(15.0)
                .padding(.horizontal)
                .frame(height: 100)
                .animation(.easeInOut(duration: 0.25).delay(0.05), value: isSymptomLogged)
            HStack(alignment: .center) {
                Image(systemName: "exclamationmark.magnifyingglass")
                    .foregroundStyle(.yellow)
                    .padding(10)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))

                VStack(alignment: .leading) {
                    Text(symptomModel.name)
                        .font(.headline)
                        .fontDesign(.rounded)
                }
                .animation(.easeInOut(duration: 0.25).delay(0.05), value: isSymptomLogged)
                .padding(.leading)

                Spacer()

                Button {
                    isShowingPicker.toggle()
                } label: {
                    SymtomLogButton(isSymptomLogged: isSymptomLogged)
                }
                .buttonStyle(.plain)
                .disabled(isSymptomLogged)
                .padding(.trailing)
            }
            .padding()
        }
        .onTapGesture {
            if !isSymptomLogged {
                // Disable after completing the log.
                isShowingPicker.toggle()
            }
        }
        .sheet(isPresented: $isShowingPicker) {
            EmojiPicker(symptomModel: symptomModel, isSymptomLogged: $isSymptomLogged)
        }
    }
}
