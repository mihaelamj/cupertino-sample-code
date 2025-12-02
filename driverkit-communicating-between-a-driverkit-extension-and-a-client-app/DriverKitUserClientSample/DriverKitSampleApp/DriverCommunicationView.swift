/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI view that provides the userclient communication UI.
*/

import SwiftUI

struct DriverCommunicationView: View {

    @Binding var displayedView: DriverKitSampleView.DisplayedView
    @ObservedObject public var viewModel: DriverCommunicationViewModel = .init()

    var body: some View {
        VStack {

            headerView

            if viewModel.isConnected {
                VStack(alignment: .leading) {
                    uncheckedView
                    checkedView
                    asyncView
                }
            } else {
                VStack(alignment: .center) {
                    Text("Driver is not connected")
                }
            }

        }.padding().frame(alignment: .center)
    }

    private var headerView: some View {
        VStack(alignment: .center) {
            Text("Driver Communication").font(.title)

            HStack(alignment: .center) {
                Button(
                    action: {
                        displayedView = .stateManagement
                    }, label: {
                        Text("Manage Dext")
                    }
                ).padding([.leading, .trailing, .bottom], nil)
            }

            if viewModel.isConnected {
                Text(viewModel.stateDescription).font(.callout)
            }
        }.padding([.leading, .trailing, .bottom])
    }

    private var uncheckedView: some View {
        VStack(alignment: .leading) {
            Text("Unchecked").font(.title2)

            HStack(alignment: .center) {
                Button(
                    action: {
                        viewModel.SwiftUncheckedScalar()
                    }, label: {
                        Text("Scalar")
                    }
                ).padding([.trailing])

                Button(
                    action: {
                        viewModel.SwiftUncheckedStruct()
                    }, label: {
                        Text("Struct")
                    }
                ).padding([.trailing])

                Button(
                    action: {
                        viewModel.SwiftUncheckedLargeStruct()
                    }, label: {
                        Text("Large Struct")
                    }
                ).padding([.trailing])
            }
        }.padding([.bottom])
    }

    private var checkedView: some View {
        VStack(alignment: .leading) {
            Text("Checked").font(.title2)

            HStack(alignment: .center) {
                Button(
                    action: {
                        viewModel.SwiftCheckedScalar()
                    }, label: {
                        Text("Scalar")
                    }
                ).padding([.trailing])

                Button(
                    action: {
                        viewModel.SwiftCheckedStruct()
                    }, label: {
                        Text("Struct")
                    }
                ).padding([.trailing])
            }
        }.padding([.bottom])
    }

    private var asyncView: some View {
        VStack(alignment: .leading) {
            Text("Async").font(.title2)

            HStack(alignment: .center) {
                Button(
                    action: {
                        viewModel.SwiftAssignAsyncCallback()
                    }, label: {
                        Text("Assign Callback")
                    }
                ).padding([.trailing])

                Button(
                    action: {
                        viewModel.SwiftSubmitAsyncRequest()
                    }, label: {
                        Text("Async Action")
                    }
                ).padding([.trailing])
            }
        }.padding([.bottom])
    }
}

struct DriverCommunicationView_Previews: PreviewProvider {

    let displayedView: DriverKitSampleView.DisplayedView = .communication

    static var previews: some View {
        Group {
            DriverCommunicationView(
                displayedView: .constant(.communication),
                viewModel: DriverCommunicationViewModel(isConnected: false)
            )

            DriverCommunicationView(
                displayedView: .constant(.communication),
                viewModel: DriverCommunicationViewModel(isConnected: true)
            )
        }

    }
}
