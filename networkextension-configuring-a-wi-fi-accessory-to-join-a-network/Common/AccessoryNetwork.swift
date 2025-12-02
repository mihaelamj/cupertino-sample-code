/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The AccessoryNetwork structure to hold information about the accessory network and connection.
*/
import Foundation

/// AccessoryNetwork defines the data necessary to associate with the accessory and make a WebSocket connection.
struct AccessoryNetwork {
    
    // MARK: - Public Variables
    
    var accessorySSID: String
    var accessoryPassphrase: String
    var scheme: String
    var host: String
    var port: String
    var psk: String
    var pskIdentity: String
    
    var qrCodeString: String {
        return [
            accessorySSID,
            accessoryPassphrase,
            scheme,
            host,
            port,
            psk,
            pskIdentity
        ].joined(separator: "|")
    }
    var accessoryConnectionInfo: (scheme: String, host: String, port: String, psk: String, pskIdentity: String) {
        return (scheme: scheme,
                host: host,
                port: port,
                psk: psk,
                pskIdentity: pskIdentity)
    }
    
    enum ParserError: Error {
        case networkCredentialError(AccessoryParseError)
        case schemeError(AccessoryParseError)
        case hostError(AccessoryParseError)
        case tlsError(AccessoryParseError)
        case badDataError(AccessoryParseError)
    }
}

struct AccessoryParseError: Error {
    var localizedDescription: String
    init(description: String) {
        localizedDescription = description
    }
}

/// The parser for AccessoryNetwork type.
extension AccessoryNetwork {
    
    init (with qrCodeString: String) throws {
        
        let accessoryComponents = qrCodeString.components(separatedBy: "|")
        
        // Make sure the separated values make an array large enough to parse all values.
        guard accessoryComponents.count == 7 else {
            throw ParserError.badDataError(AccessoryParseError(description: "QR code data not structured correctly"))
        }
        
        guard !accessoryComponents[0].isEmpty, !accessoryComponents[1].isEmpty else {
            throw ParserError.networkCredentialError(AccessoryParseError(description: "SSID and Passphrase were not set"))
        }
        // Set the network credentials.
        accessorySSID = accessoryComponents[0]
        accessoryPassphrase = accessoryComponents[1]
        
        guard accessoryComponents[2] == "wss" else {
            throw ParserError.schemeError(AccessoryParseError(description: "Error setting host scheme"))
        }
        // Set scheme - wss for wss://.
        scheme = accessoryComponents[2]
        
        guard !accessoryComponents[3].isEmpty else {
            throw ParserError.hostError(AccessoryParseError(description: "Error setting host correctly due to length"))
        }
        // Set the host.
        host = accessoryComponents[3]
        
        guard let assignedPort = UInt16(accessoryComponents[4]),
              assignedPort != 0 else {
            throw ParserError.hostError(AccessoryParseError(description: "Error setting port correctly on the host"))
        }
        // Set the port.
        port = accessoryComponents[4]
        
        guard !accessoryComponents[5].isEmpty, !accessoryComponents[6].isEmpty else {
            throw ParserError.tlsError(AccessoryParseError(description: "PSK and PSK Identity were not set"))
        }
        // Set TLS PSK and PSK Identity.
        pskIdentity = accessoryComponents[6]
        psk = accessoryComponents[5]
    }
}
