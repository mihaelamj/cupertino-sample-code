/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Main handler for PushKit events
*/

import Foundation
import CallKit
import PushKit

class PushRegistryDelegate: NSObject {
    private let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
    weak var providerDelegate: ProviderDelegate?
    
    init(providerDelegate: ProviderDelegate) {
        self.providerDelegate = providerDelegate
        super.init()
        
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
    }
}

extension PushRegistryDelegate: PKPushRegistryDelegate {
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials,
                      for type: PKPushType) {
        /*
         Store push credentials on the server for the active user.
         */
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        print("pushRegistry invalidated: \(type)\n")
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload,
                      for type: PKPushType, completion: @escaping () -> Void) {
        let dictionaryPayload = payload.dictionaryPayload
        print("dictionaryPayload: \(dictionaryPayload)\n")

        defer {
            completion()
        }

        guard type == .voIP,
            let uuidString = payload.dictionaryPayload["UUID"] as? String,
            let handle = payload.dictionaryPayload["handle"] as? String,
            payload.dictionaryPayload["hasVideo"] != nil,
            let uuid = UUID(uuidString: uuidString)
            else {
                return
        }
        
        providerDelegate?.reportIncomingCall(uuid: uuid, handle: handle)
    }
}
