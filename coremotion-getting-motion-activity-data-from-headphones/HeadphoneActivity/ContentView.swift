/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays headphone activity.
*/
import SwiftUI

struct ContentView: View {

    /// The model of the content view.
    @StateObject private var contentViewState = ContentViewState()

    var body: some View {
        VStack {
            Toggle(isOn: $contentViewState.isEnabled) {
                Text("Headphone Activity").frame(maxWidth: .infinity, alignment: .trailing)
            }.padding(.bottom, 50)
            Spacer()
            Text(contentViewState.activity)
                .padding()
                .font(.title)
                .foregroundColor(Color.white)
                .background(Color.blue)
                .cornerRadius(10)
            Spacer()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
