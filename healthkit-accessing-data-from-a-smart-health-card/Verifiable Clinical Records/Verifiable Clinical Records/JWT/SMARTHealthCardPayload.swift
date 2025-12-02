/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The payload for a SMART health Card.
*/

import Foundation

struct SMARTHealthCardPayload: Codable {
    
    public struct VC: Codable {
        
        public let type: [String]
        
         public let credentialSubject: CredentialSubject
    }
    
    /// The issuer field.
    public let iss: String
    
    /// The not before field.
    public let nbf: Double?
    
    /// The expires at field.
    public let exp: Double?
    
    /// The verifiable credential field.
    public let vc: VC
}

struct CredentialSubject: Codable {
    
    public let fhirVersion: String
    
    // Implement fhirBundle here using the FHIRModels Swift Package.
}
