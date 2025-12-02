/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A central hub for home delegates.
*/

import HomeKit

extension HomeStore {
    /// Registers an object as a home delegate.
    func addHomeDelegate(_ delegate: NSObject) {
        homeDelegates.insert(delegate)
    }
    
    /// Deregisters a particular home delegate.
    func removeHomeDelegate(_ delegate: NSObject) {
        homeDelegates.remove(delegate)
    }
    
    /// Deregisters all home delegates.
    func removeAllHomeDelegates() {
        homeDelegates.removeAll()
    }
}

extension HomeStore: HMHomeDelegate {
    
    // The home store's only interest in the home updates is distributing them
    //  to the objects that have registered as home delegates. Each of these
    //  methods therefore simply passes along the call to all the items in the set,
    //  after first ensuring that the item is in fact a home delegate.
    
    func homeDidUpdateName(_ home: HMHome) {
        homeDelegates.forEach {
            guard let delegate = $0 as? HMHomeDelegate else { return }
            delegate.homeDidUpdateName?(home)
        }
    }

    func home(_ home: HMHome, didAdd accessory: HMAccessory) {
        homeDelegates.forEach {
            guard let delegate = $0 as? HMHomeDelegate else { return }
            delegate.home?(home, didAdd: accessory)
        }
    }
    
    func home(_ home: HMHome, didUpdate room: HMRoom, for accessory: HMAccessory) {
        homeDelegates.forEach {
            guard let delegate = $0 as? HMHomeDelegate else { return }
            delegate.home?(home, didUpdate: room, for: accessory)
        }
    }
    
    func home(_ home: HMHome, didRemove accessory: HMAccessory) {
        homeDelegates.forEach {
            guard let delegate = $0 as? HMHomeDelegate else { return }
            delegate.home?(home, didRemove: accessory)
        }
    }
    
    func home(_ home: HMHome, didAdd room: HMRoom) {
        homeDelegates.forEach {
            guard let delegate = $0 as? HMHomeDelegate else { return }
            delegate.home?(home, didAdd: room)
        }
    }
    
    func home(_ home: HMHome, didUpdateNameFor room: HMRoom) {
        homeDelegates.forEach {
            guard let delegate = $0 as? HMHomeDelegate else { return }
            delegate.home?(home, didUpdateNameFor: room)
        }
    }

    func home(_ home: HMHome, didRemove room: HMRoom) {
        homeDelegates.forEach {
            guard let delegate = $0 as? HMHomeDelegate else { return }
            delegate.home?(home, didRemove: room)
        }
    }

    func home(_ home: HMHome, didEncounterError error: Error, for accessory: HMAccessory) {
        homeDelegates.forEach {
            guard let delegate = $0 as? HMHomeDelegate else { return }
            delegate.home?(home, didEncounterError: error, for: accessory)
        }
   }
}

