/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension that provides a signature verification method.
*/

import Foundation
import CryptoKit

extension JWS {
    
    public func verifySignature() async throws -> Bool {
        // Decode the body of the JWS to the SMART Health Card format.
        let jsonDecoder = JSONDecoder()
        let decodedPayload = try jsonDecoder.decode(SMARTHealthCardPayload.self, from: payload)
        let decodedHeader = try jsonDecoder.decode(JWSHeader.self, from: Base64URL.decode(header))
        
        let issuerIdentifier = decodedPayload.iss
        guard URLIsTrusted(url: issuerIdentifier) else {
            throw VerificationError.untrustedIssuer(issuerIdentifier)
        }
        
        // The standard URL to locate an issuer's signing public keys is
        // constructed by appending `/.well-known/jwks.json` to
        // the issuer's identifier.
        let urlString = decodedPayload.iss + "/.well-known/jwks.json"
        guard let url = URL(string: urlString) else {
            throw VerificationError.unableToParseIssuerURL(urlString)
        }
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = 5.0
        let session = URLSession(configuration: configuration)
        let (data, _) = try await session.data(from: url, delegate: nil)
        let keySet = try jsonDecoder.decode(JWKSet.self, from: data)
        let signingKey = try keySet.key(with: decodedHeader.kid)
        
        return try signatureIsValid(signingKey: signingKey)
    }
    
    private func URLIsTrusted(url: String) -> Bool {
        // The set of issuers to trust.
        let trustedURLs: Set = [
            "https://smarthealth.cards/examples/issuer",
            "https://spec.smarthealth.cards/examples/issuer"
        ]
        return trustedURLs.contains(url)
    }
    
    private func signatureIsValid(signingKey: JWK) throws -> Bool {
        let headerAndPayloadString = header + "." + payloadString
        guard let message = headerAndPayloadString.data(using: .utf8) else {
            throw VerificationError.failedToCreateUTF8DataFromString
        }
        
        let signingPublicKey = try signingKey.asP256PublicKey()
        let decodedSignature = try Base64URL.decode(signature)
        let parsedECDSASignature = try P256.Signing.ECDSASignature(rawRepresentation: decodedSignature)
        return signingPublicKey.isValidSignature(parsedECDSASignature, for: message)
    }
}

enum VerificationError: Error {
    case untrustedIssuer(String)
    case unableToParseIssuerURL(String)
    case failedToCreateUTF8DataFromString
}
