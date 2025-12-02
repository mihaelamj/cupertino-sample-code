/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The NWParameters extension that NWListener and NWConnection use for TLS and the NWProtocolWebSocket.
*/

import Network
import CryptoKit
import Foundation

extension NWParameters {
    
    convenience init(psk: String, pskIdentity: String) {
        // Create parameters with custom TLS and TCP options (Default with TLS).
        self.init(tls: NWParameters.tlsOptions(psk: psk, pskIdentity: pskIdentity))
        
        // Use the WebSocket protocol.
        let webSocketOptions = NWProtocolWebSocket.Options()
        self.defaultProtocolStack.applicationProtocols.insert(webSocketOptions, at: 0)
    }
    
    /// Create TLS options with a preshared key and its identity to use on both NWListener and NWConnection.
    private static func tlsOptions(psk: String, pskIdentity: String) -> NWProtocolTLS.Options {
        let tlsOptions = NWProtocolTLS.Options()
        
        sec_protocol_options_set_min_tls_protocol_version(tlsOptions.securityProtocolOptions, .TLSv12)
        sec_protocol_options_append_tls_ciphersuite(
            tlsOptions.securityProtocolOptions,
            tls_ciphersuite_t(rawValue: UInt16(TLS_PSK_WITH_AES_128_GCM_SHA256))!
        )
        
        let pskData = Data(psk.utf8)
        let pskDispatchData = pskData.withUnsafeBytes { buf in
            DispatchData(bytes: buf)
        }
        
        let pskIdentityData = Data(pskIdentity.utf8)
        let pskIdentityDispatchData = pskIdentityData.withUnsafeBytes { buf in
            DispatchData(bytes: buf)
        }
        
        sec_protocol_options_add_pre_shared_key(
            tlsOptions.securityProtocolOptions,
            pskDispatchData as __DispatchData,
            pskIdentityDispatchData as __DispatchData
        )
        return tlsOptions
    }
    
}
