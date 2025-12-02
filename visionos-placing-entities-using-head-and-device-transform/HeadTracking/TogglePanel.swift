/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Shows the toggle between launching the entities and having it follow the person.
*/

import SwiftUI

struct TogglePanel: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) var dismissImmersiveSpace
    var body: some View {
        @Bindable var appModel = appModel
        Group {
            if !appModel.isImmersiveSpaceOpen {
                Button("Launch hummingbird") {
                    Task {
                        await openImmersiveSpace(id: "immersiveSpace")
                        appModel.isImmersiveSpaceOpen = true
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Text("Currently enabled: \(appModel.headTrackState.rawValue.capitalized) mode")
                    Picker("Current state", selection: $appModel.headTrackState) {
                        // Iterate through the head-position and follow cases.
                        ForEach(AppModel.HeadTrackState.allCases, id: \.self) { state in
                            Text("\(state.rawValue.capitalized) mode")
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Spacer()
                    Button("Exit immersive space") {
                        Task {
                            await dismissImmersiveSpace()
                            appModel.isImmersiveSpaceOpen = false
                        }
                    }
                }
                .padding()
            }
        }
    }
}
