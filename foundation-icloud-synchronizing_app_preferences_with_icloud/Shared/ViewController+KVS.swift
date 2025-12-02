/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Shared code for NSUbiquitousKeyValueStore notification handling.
*/

import Foundation

let gBackgroundColorKey = "backgroundColor"

// MARK: NSUbiquitousKeyValueStore Support

extension ViewController {

    func prepareKeyValueStoreForUse() {

		/** Listen for key-value store changes from iCloud.
			This notification is posted when the value of one or more keys in the local
			key-value store changed due to incoming data pushed from iCloud.
		*/
		NotificationCenter.default.addObserver(self,
			selector: #selector(ubiquitousKeyValueStoreDidChange(_:)),
			name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
			object: NSUbiquitousKeyValueStore.default)
		/** Note: By passing the default key-value store object as "object" it tells iCloud that
			this is the object whose notifications you want to receive.
		*/
		
        // Get any KVStore change since last launch.
		
		/** This will spark the notification "NSUbiquitousKeyValueStoreDidChangeExternallyNotification",
			to ourselves to listen for iCloud KVStore changes.
		
			It is important to only do this step *after* registering for notifications,
			this prevents a notification arriving before code is ready to respond to it.
		*/
        if NSUbiquitousKeyValueStore.default.synchronize() == false {
            fatalError("This app was not built with the proper entitlement requests.")
        }
    }
    
    /** This notification is sent only upon a change received from iCloud; it is not sent when your app
		sets a value. So this is called when the key-value store in the cloud has changed externally.
     	The old color value is replaced with the new one. Additionally, NSUserDefaults is updated as well.
    */
    @objc
    func ubiquitousKeyValueStoreDidChange(_ notification: Notification) {
        
        /** We get more information from the notification, by using:
            NSUbiquitousKeyValueStoreChangeReasonKey or NSUbiquitousKeyValueStoreChangedKeysKey
            constants on the notification's useInfo.
         */
		guard let userInfo = notification.userInfo else { return }
        
		// Get the reason for the notification (initial download, external change or quota violation change).
		guard let reasonForChange = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else { return }
		
        /** Reasons can be:
            NSUbiquitousKeyValueStoreServerChange:
            Value(s) were changed externally from other users/devices.
            Get the changes and update the corresponding keys locally.
         
            NSUbiquitousKeyValueStoreInitialSyncChange:
            Initial downloads happen the first time a device is connected to an iCloud account,
            and when a user switches their primary iCloud account.
            Get the changes and update the corresponding keys locally.

            Do the merge with our local user defaults.
            But for this sample we have only one value, so a merge is not necessary here.

            Note: If you receive "NSUbiquitousKeyValueStoreInitialSyncChange" as the reason,
            you can decide to "merge" your local values with the server values.

            NSUbiquitousKeyValueStoreQuotaViolationChange:
            Your app’s key-value store has exceeded its space quota on the iCloud server of 1mb.

            NSUbiquitousKeyValueStoreAccountChange:
            The user has changed the primary iCloud account.
            The keys and values in the local key-value store have been replaced with those from the new account,
            regardless of the relative timestamps.
         */
        
        // Check if any of the keys we care about were updated, and if so use the new value stored under that key.
		guard let keys =
            userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else { return }
		
		guard keys.contains(gBackgroundColorKey) else { return }

        if reasonForChange == NSUbiquitousKeyValueStoreAccountChange {
            // User changed account, so fall back to use UserDefaults (last color saved).
            chosenColorValue = UserDefaults.standard.integer(forKey: gBackgroundColorKey)
            return
        }
        
        /** Replace the "selectedColor" with the value from the cloud, but *only* if it's a value we know how to interpret.
            It is important to validate any value that comes in through iCloud, because it could have been generated
            by a different version of your app.
         */
		let possibleColorIndexFromiCloud =
            NSUbiquitousKeyValueStore.default.longLong(forKey: gBackgroundColorKey)
		
        if let validColorIndex = ColorIndex(rawValue: Int(possibleColorIndexFromiCloud)) {
            chosenColorValue = validColorIndex.rawValue
            return
        }
        
        /** The value isn't something we can understand.
         	The best way to handle an unexpected value depends on what the value represents, and what your app does.
         	 good rule of thumb is to ignore values you can not interpret and not apply the update.
         */
        Swift.debugPrint("WARNING: Invalid \(gBackgroundColorKey) value,")
        Swift.debugPrint("of \(possibleColorIndexFromiCloud) received from iCloud. This value will be ignored.")
    }
}

// MARK: - Color Support

extension ViewController {
    
    /** The key-value store is not a replacement for NSUserDefaults or other local techniques for saving the same data.
     	The purpose of the key-value store is to share data between apps, but if iCloud is not enabled or is not available on a given device,
    	you still will want to keep a local copy of the data.
     
     	For more information, see the "Preferences and Settings Programming Guide: Storing Preferences in iCloud".
     
     	It is important to keep your NSUserDefaults and NSUbiquitousKeyValueStore values in sync.
     	It helps to only update them from a method that updates them both.
     
     	We always read the chosen color from local NSUserDefaults.
     	NSUbiquitousKeyValueStore is used to update NSUserDefaults.
     	Default is kColorWhite (0) if no color has been chosen yet.
     */
    var chosenColorValue: Int {
        get {
            return UserDefaults.standard.integer(forKey: gBackgroundColorKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: gBackgroundColorKey)
            NSUbiquitousKeyValueStore.default.set(newValue, forKey: gBackgroundColorKey)
            updateUserInterface()
        }
    }
}
