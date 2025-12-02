/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view of the iOS app.
*/

import SwiftUI

/// A view that displays the device's current characteristic value.
struct RootView: View {
    
    var body: some View {
        
        Text("\(Int(ApplicationDelegate.instance.peripheralValue.value))\(ApplicationDelegate.instance.peripheralValue.unit.symbol)")
                .font(.title.bold())

        Button(action: {
            print("sending timely alert")
            ApplicationDelegate.instance.bluetoothSender.sendTimelyAlert()
        }) {
            Text("Send temperature alert")
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
