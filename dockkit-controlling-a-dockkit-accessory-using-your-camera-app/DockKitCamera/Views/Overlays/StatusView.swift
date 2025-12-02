/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the current connection and battery status.
*/

import SwiftUI

/// A view that displays the current connection and battery status.
struct StatusView<DockControllerModel: DockController>: View {
    
    @State var dockController: DockControllerModel
    
    var body: some View {
        HStack(spacing: 30) {
            Spacer()
            ConnectionView(connected: dockController.status != .disconnected ? true : false,
                           tracking: dockController.status == .connectedTracking)
            
            BatteryView(fill: .green, outline: .white, percentage: dockController.battery.percentage,
                        charging: dockController.battery.charging,
                        available: batteryAvailable(dockController.battery))
        }
        //.buttonStyle(DefaultButtonStyle(size: isRegularSize ? .large : .small))
        .padding([.leading, .trailing])
    }
    
    private func batteryAvailable(_ status: DockAccessoryBatteryStatus) -> Bool {
        switch status {
        case .unavailable:
            return false
        case .available(percentage: _, charging: _):
            return true
        }
    }
}

#Preview {
    StatusView(dockController: DockControllerModel())
}
