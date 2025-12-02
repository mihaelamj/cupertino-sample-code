/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Methods that manage orders in the app.
*/

import ActivityKit
import WidgetKit
import SwiftUI

struct Order {
    var hoagieOrder: TestHoagieData.HoagieOrder
}

enum OrderingError: Error {
    case errorOrdering
    case pushError
}

final class OrderingService: ObservableObject {
    
    static let service = OrderingService()
    private static let orderStatusKey = "OrderStatus"
    var orderActivity: Activity<OrderStatusAttributes>?
    var updateTokens = [String: String]()
    
    @Published var inCarPlay = false
    @Published var orderState: OrderStatusAttributes.ContentState =
    OrderStatusAttributes.stateForValue(value: OrderStatusAttributes.ContentStateValues(
        rawValue: TestHoagieData.hoagieDefaults.string(forKey: OrderingService.orderStatusKey)
            ?? ""))
    
    static func placeOrder(hoagieOrder: TestHoagieData.HoagieOrder) throws {
        MemoryLogger.shared.appendEvent("Placing Order: \(hoagieOrder.order.joined(separator: ""))")
        guard sendOrderToHoagieMakers() else { fatalError("The false API always returns true.") }
        Task {
            await cleanupActivities()
            
//          There is the option to use `pushToStartTokenUpdates` and get a token to start the Live Activity at a later date.
//            Task { @MainActor in
//                for await token in Activity<OrderStatusAttributes>.pushToStartTokenUpdates {
//                    let pushToStartTokenString = token.reduce("") {
//                        $0 + String(format: "%02x", $1)
//                    }
//                    MemoryLogger.shared.appendEvent("pushToStartTokenUpdates token: \(pushToStartTokenString)")
//                    try await self.sendPushToStartToken(hoagieOrder: hoagieOrder, pushTokenString: pushToStartTokenString)
//                }
//            }
            
                /// - Tag: live
            MemoryLogger.shared.appendEvent("Placing Order")
            do {
                
//             Simulate a scenario where a person using the app enters a tunnel with no service just as they
//             place an order. The test API can't confirm the order in `sendOrderToHoagieMakers()`, and then the app loses service.
//             The Live Activity starts manually.
                let attrs = OrderStatusAttributes(hoagieOrder: hoagieOrder)
                let initialState = OrderStatusAttributes.ContentState(
                    isPickedUp: false,
                    isReady: false,
                    isPreparing: false,
                    isConfirmed: true)
                
                try saveOrderState(state: initialState)
                
                MemoryLogger.shared.appendEvent("Starting Live Activity")
                OrderingService.service.orderActivity = try Activity.request(
                    attributes: attrs,
                    content: .init(state: initialState, staleDate: Date(timeIntervalSinceNow: 60 * 30)),
                    pushType: .token
                )
                try await finalizeOrder(hoagieOrder: hoagieOrder)
            } catch {
                throw OrderingError.errorOrdering
            }
        }
    }
    
//  Return success for the purposes of this demonstration.
    private static func sendOrderToHoagieMakers() -> Bool { true }
    
    private static func saveOrderState(state: OrderStatusAttributes.ContentState) throws {
        MemoryLogger.shared.appendEvent("Saving order status \(state)")
        TestHoagieData.hoagieDefaults.set(OrderStatusAttributes.valueForState(value: state).rawValue, forKey: orderStatusKey)
    }
    
    private static func finalizeOrder(hoagieOrder: TestHoagieData.HoagieOrder) async throws {
        MemoryLogger.shared.appendEvent("Saving Order")
        TestHoagieData.saveLastOrder(order: hoagieOrder)
        guard let activity = OrderingService.service.orderActivity else {
            throw OrderingError.errorOrdering
        }
        
        MemoryLogger.shared.appendEvent("Houston, we have Live Activity.")
        
//      For the purposes of this demonstration, hoagies are ready in 10 minutes or less.
//      Here, a push notification indicates whether an order is ready earlier.
//      Spin off another thread to listen for updates.
        Task { @MainActor in
            MemoryLogger.shared.appendEvent("Change Listener Task Started")
            for await change in activity.contentUpdates {
                MemoryLogger.shared.appendEvent("Content update change \(change.description)")
                try saveOrderState(state: change.state)
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        
        Task { @MainActor in
            MemoryLogger.shared.appendEvent("State Listener Task Started")
            for await state in activity.activityStateUpdates {
                MemoryLogger.shared.appendEvent("Content update change \(state)")
                if state == .dismissed || state == .ended {
                    await activity.end(nil, dismissalPolicy: .immediate)
                    OrderingService.service.updateTokens[activity.id] = nil
                }
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        
        Task { @MainActor in
            MemoryLogger.shared.appendEvent("Push Token Update Listener Task Started")
            for await pushToken in activity.pushTokenUpdates {
                let pushTokenString = pushToken.reduce("") {
                    $0 + String(format: "%02x", $1)
                }
                
                OrderingService.service.updateTokens[activity.id] = pushTokenString
                try await self.sendPushToken(hoagieOrder: hoagieOrder, pushTokenString: pushTokenString)
            }
        }
    }
    
    private static func sendPushToken(
        hoagieOrder: TestHoagieData.HoagieOrder,
        pushTokenString: String,
        frequentUpdateEnabled: Bool = false) async throws {
            print(pushTokenString)
            MemoryLogger.shared.appendEvent("saving push token \(pushTokenString)")
    }
    
    private static func sendPushToStartToken(
        hoagieOrder: TestHoagieData.HoagieOrder,
        pushTokenString: String,
        frequentUpdateEnabled: Bool = false) async throws {
            print(pushTokenString)
            MemoryLogger.shared.appendEvent("saving push to start token \(pushTokenString)")
            MemoryLogger.shared.appendEvent("Use push to start token \(pushTokenString) in the Hoagies Push Server to start the order.")
    }
    
    private static func cleanupActivities() async {
        // Clean up any activities.
        MemoryLogger.shared.appendEvent("Cleaning old activities")
        for activity in Activity<OrderStatusAttributes>.activities {
            await activity.end(.none, dismissalPolicy: .immediate)
        }
        MemoryLogger.shared.appendEvent("Done cleaning old activities")
    }
}
