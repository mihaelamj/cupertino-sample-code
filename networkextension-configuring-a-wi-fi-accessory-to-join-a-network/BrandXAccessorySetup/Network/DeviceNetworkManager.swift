/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The DeviceNetworkManager class to manage data for the accessory network.
*/

import Foundation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

final class DeviceNetworkManager {
    
    // MARK: - Private Variables
    
    private var originalAssociatedSSID: String = ""
    
    // MARK: - Public Constants
    
    static let shared = DeviceNetworkManager()
    
    // MARK: - Public Variables
    
    public var accessoryNetwork: AccessoryNetwork?
    
    // MARK: - Instance Methods
    
    /// @function getOriginalAssociatedSSID
    /// @discussion Getter for originalAssociatedSSID.  This is the user’s original SSID association before associating with BrandXAccessory.
    func getOriginalAssociatedSSID() -> String {
        return originalAssociatedSSID
    }
    
    /// @function setOriginalAssociatedSSID
    /// @discussion The setter for originalAssociatedSSID.
    ///           Sets the originalAssociatedSSID to direct the user to rejoin this SSID after transferring network credentials.
    func setOriginalAssociatedSSID(originalAssociatedSSID: String) {
        self.originalAssociatedSSID = originalAssociatedSSID
    }
    
    /// @function associatedSSIDs
    /// @discussion Get the supported interfaces at the time of the call and map an SSID with the current network information.
    /// @return An array of associated SSIDs for the device.
    /// @NOTE: CNCopyCurrentNetworkInfo is deprecated in iOS 13, so use NEHotspotNetwork.fetchCurrent in iOS 14.
    func associatedSSIDs(completion: @escaping ((_ result: [String]) -> Void)) {
        if #available(iOS 14, *) {
            NEHotspotNetwork.fetchCurrent() { (network) in
                let networkSSID = network.flatMap { [$0.ssid] } ?? []
                completion(networkSSID)
            }
        } else {
            // For iOS 13 and earlier.
            guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else {
                completion([])
                return
            }
            
            completion(interfaceNames.compactMap { name in
                guard let info = CNCopyCurrentNetworkInfo(name as CFString) as? [String: AnyObject] else {
                    return nil
                }
                
                guard let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
                    return nil
                }
                return ssid
            })
        }
    }
}
