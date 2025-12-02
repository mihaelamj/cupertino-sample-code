/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI view that provides the driver loading UI for macOS.
*/

import SwiftUI

struct DriverLoadingView: View {

    @Binding var displayedView: DriverKitSampleView.DisplayedView
    @ObservedObject var viewModel: DriverLoadingViewModel = .init()

    var body: some View {
        VStack(alignment: .center) {
            Text("Driver Manager")
                .padding()
                .font(.title)
            Text(self.viewModel.dextLoadingState)
                .multilineTextAlignment(.center)
            HStack {
                Button(
                    action: {
                        self.viewModel.activateMyDext()
                    }, label: {
                        Text("Install Dext")
                    }
				)
                Button(
                    action: {
                        displayedView = .communication
                    }, label: {
                        Text("Communicate With Dext")
                    }
                )
            }
        }.frame(width: 500, height: 200, alignment: .center)
    }
}

struct DriverLoadingView_Previews: PreviewProvider {

    @State var displayedView: DriverKitSampleView.DisplayedView = .stateManagement

    static var previews: some View {
        DriverLoadingView(displayedView: .constant(.stateManagement))
    }
}
