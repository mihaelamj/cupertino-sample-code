/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The WebSocketMessage is a definition for a message that the sample sends on the WebSocket connection.
*/

import Foundation

struct WebSocketMessage: Codable {
    
    var ssid: String = ""
    var passphrase: String = ""
    var status: String = ""
    
}
