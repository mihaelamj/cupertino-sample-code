/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The project constants.
*/

import Foundation

enum Constants {
    /// The name of the SSID that BrandXAccessory uses during the Internet Sharing session.
    /// Set this as the default SSID, or Network Name in System Preferences.
    /// A real accessory obviously knows the SSID it's publishing. This sample hardcodes the SSID
    /// because there is no API to get the SSID that Internet Sharing is using.
    /// This information is in the QR code and the sample sends it to iOS to use in NEHotspotConfiguration.
    static let accessorySSID = "AccessoryWiFi"
    
    /// The passphrase, or password, for the Internet Sharing session.
    /// Set this as the password in System Preferences.
    /// A real accessory obviously knows the passphrase it's publishing. This sample hardcodes the passphrase
    /// because there is no API to get the passphrase that Internet Sharing is using.
    /// This information is in the QR code and the sample sends it to iOS to use in NEHotspotConfiguration.
    static let accessoryPassphrase = "embedded1"
    
    /// The port the WebSocketListener uses to listen for connections.
    /// This information is in the QR code.
    static let port = "443"
}
