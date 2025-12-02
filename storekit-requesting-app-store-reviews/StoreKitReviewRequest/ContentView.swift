/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that holds the app's visual content.
*/

import SwiftUI

struct ContentView: View {
    @State var path: [StepItem] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            Button("Start Process") {
                path.append(.first)
            }
            .font(.title2)
            .frame(maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 16) {
                    WriteReviewLink()
                    ResetButton()
                }
            }
            .navigationDestination(for: StepItem.self) { item in
                StepView(item: item, path: $path)
            }
            .navigationBarBackButtonHidden()
        }
    }
}

#Preview {
    ContentView()
}
