/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A singleton for holding the home manager.
*/

import UIKit
import HomeKit

/// - Tag: HomeStore
class HomeStore: NSObject {
    /// A singleton that can be used anywhere in the app to access the home manager.
    static var shared = HomeStore()
    
    /// The one and only home manager that belongs to the home store singleton.
    let homeManager = HMHomeManager()
    
    /// A set of objects that want to receive home delegate callbacks.
    var homeDelegates = Set<NSObject>()
    
    /// A set of objects that want to receive accessory delegate callbacks.
    var accessoryDelegates = Set<NSObject>()
}

// Actions performed by a given client that change HomeKit state don't generate
//  delegate callbacks in the same client. These convenience methods each
//  perform a particular update and make the corresponding delegate call.
extension HomeStore {
    
    /// Updates the name of a service and informs all accessory delegates.
    func updateService(_ service: HMService, name: String) {
        service.updateName(name) { error in
            if let error = error {
                print(error)
            } else if let accessory = service.accessory {
                self.accessory(accessory, didUpdateNameFor: service)
            }
        }
    }
    
    /// Moves an accessory to a given room and informs all the home delegates.
    func move(_ accessory: HMAccessory, in home: HMHome, to room: HMRoom) {
        home.assignAccessory(accessory, to: room) { error in
            if let error = error {
                print(error)
            } else {
                self.home(home, didUpdate: room, for: accessory)
            }
        }
    }
    
    /// Removes an accessory from a home and informs all the home delegates.
    func remove(_ accessory: HMAccessory, from home: HMHome) {
        home.removeAccessory(accessory) { error in
            if let error = error {
                print(error)
            } else {
                self.home(home, didRemove: accessory)
            }
        }
    }
}
