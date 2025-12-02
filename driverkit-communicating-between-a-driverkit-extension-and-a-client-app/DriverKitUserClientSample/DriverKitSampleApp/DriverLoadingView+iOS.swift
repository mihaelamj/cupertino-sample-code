/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI view that provides the driver loading UI for iPadOS.
*/

import SwiftUI
import UIKit

struct DriverLoadingView: View {

	@Binding var displayedView: DriverKitSampleView.DisplayedView

	var body: some View {
		VStack(alignment: .center) {
			headerView

			HStack {
                Button(
                    action: {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }, label: {
                        Text("Open Settings to Enable Driver")
                    }
                )
			}
		}
	}

    private var headerView: some View {
        VStack(alignment: .center) {
            Text("Driver Communication").font(.title)

            HStack(alignment: .center) {
                Button(
                    action: {
                        displayedView = .communication
                    }, label: {
                        Text("Communicate With Dext")
                    }
                ).padding([.leading, .trailing, .bottom], nil)
            }
        }.padding([.leading, .trailing, .bottom])
    }
}

struct DriverLoadingView_Previews: PreviewProvider {

	@State var displayedView: DriverKitSampleView.DisplayedView = .stateManagement

	static var previews: some View {
		DriverLoadingView(displayedView: .constant(.stateManagement))
	}
}
