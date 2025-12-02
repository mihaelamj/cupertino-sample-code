/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The AccessoryNetworkManager to associate with the BrandXAccessory.
*/

import Foundation
import NetworkExtension

final class AccessoryNetworkManager {
    
    // MARK: - Public Variables
    
    typealias Delegate = AccessoryNetworkManagerDelegate
    
    public weak var delegate: Delegate?
    
    public var isReady: Bool = false
    public var status: String = ""
    
    /// @function removeConfiguration
    /// @discussion Remove the hotspot configuration.
    func removeConfiguration(ssid: String) {
        NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
    }
    
    /// @function applyConfiguration
    /// @discussion Apply NEHotspotConfiguration to associate to BrandXAccessory.
    func applyConfiguration(with accessoryNetwork: AccessoryNetwork) {
        
        let config = NEHotspotConfiguration(ssid: accessoryNetwork.accessorySSID,
                                            passphrase: accessoryNetwork.accessoryPassphrase,
                                            isWEP: false)
        config.joinOnce = true
        
        NEHotspotConfigurationManager.shared.apply(config) { (error) in
            
            // This error represents NEHotspotConfigurationError.
            if let configError = error {
                self.status = configError.localizedDescription
                self.delegate?.accessoryNetworkManagerDidUpdate(acessoryNetworkManager: self)
                return
            }
            // Send traffic through the newly associated wireless network.
            self.status = "\(config.ssid) wireless network setup!"
            self.isReady = true
            self.delegate?.accessoryNetworkManagerDidUpdate(acessoryNetworkManager: self)
        }
    }
}

/// The accessoryNetworkManagerDelegate for notifying the calling class when something changes.
protocol AccessoryNetworkManagerDelegate: AnyObject {
    func accessoryNetworkManagerDidUpdate(acessoryNetworkManager: AccessoryNetworkManager)
}
