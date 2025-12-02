/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The button that presents the refill modal for the Habitat view.
*/

import SwiftUI

struct HabitatLevelButton: View {
    
    @Binding var isShowingRefillView: Bool
    
    init(_ isShowingRefillView: Binding<Bool>) {
        self._isShowingRefillView = isShowingRefillView
    }
    
    var body: some View {
        Button {
            isShowingRefillView.toggle()
        } label: {
            HStack {
                Spacer()
                Text("Refill")
                Spacer()
            }
        }
    }
}

struct HabitatLevelButton_Previews: PreviewProvider {
    static var previews: some View {
        HabitatLevelButton(.constant(false))
    }
}
