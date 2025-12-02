/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A mechanism for demonstrating the capability to store all of the different CryptoKit key types in the keychain.
*/

import Foundation
import CryptoKit
import SwiftUI
import Combine

class KeyTest: ObservableObject {
    /// Possible test outcomes.
    internal enum TestStatus: String, CaseIterable {
        case pending = ""
        case pass = "PASS"
        case fail = "FAIL"
    }
    
    /// The different kinds of keys.
    enum Category: String, CaseIterable {
        case MLKEM = "ML-KEM"
        case MLDSA = "ML-DSA"
        case PQHPKE = "PQ-HPKE"
        case hybridSig = "Hybrid Sig"
    }
    
    /// Tasks you can use the asymmetric keys for.
    enum Purpose: String, CaseIterable {
        case signing = "Signing"
        case keyAgreement = "Key Agreement"
    }

    /// ML-KEM key types.
    enum MLKEMType: String, CaseIterable {
        case MLKEM768 = "MLKEM-768"
        case MLKEM1024 = "MLKEM-1024"
    }

    /// ML-DSA key types.
    enum MLDSAType: String, CaseIterable {
        case MLDSA65 = "MLDSA-65"
        case MLDSA87 = "MLDSA-87"
    }

    /// PQ-HPKE key types.
    enum PQHPKEType: String, CaseIterable {
        case XWingMLKEM768X25519
    }

    /// Hybrid signature key types.
    enum HybridSigType: String, CaseIterable {
        case MLDSA65xP256
        case MLDSA87xP384
    }

    /// The kind of key to test.
    var category = Category.MLKEM {
        didSet {
            reset()
        }
    }

    /// A Boolean value that indicates whether to use a Secure Enclave key.
    @Published var useSecureEnclave = false {
        didSet {
            reset()
        }
    }
    
    /// An indicator of whether the current hardware supports Secure Enclave.
    var disableSecureEnclave: Bool {
        !SecureEnclave.isAvailable
    }
    
    /// The kind of asymmetric key to test, when applicable.
    var purpose = Purpose.signing {
        didSet {
            reset()
        }
    }

    /// The type of ML-KEM key to test.
    var mlkemtype = MLKEMType.MLKEM768 {
        didSet {
            reset()
        }
    }

    var mldsatype = MLDSAType.MLDSA65 {
        didSet {
            reset()
        }
    }

    var pqhpketype = PQHPKEType.XWingMLKEM768X25519 {
        didSet {
            reset()
        }
    }

    var hybridsigtype = HybridSigType.MLDSA65xP256 {
        didSet {
            reset()
        }
    }

    /// The outcome of the last test.
    @Published var status = TestStatus.pending
    
    /// A message to display to the user after running a test.
    @Published var message = ""
    
    /// Restores the startup state.
    func reset() {
        status = .pending
        message = ""
    }
    
    /// Reports the integrity of a key that travels on a round trip through the keychain.
    func run() {
        do {
            switch category {
            case .MLKEM:
                if #available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, macCatalyst 26.0, visionOS 26.0, *) {
                    (status, message) = try testMLKEM(type: mlkemtype, useSecureEnclave: useSecureEnclave)
                } else {
                    (status, message) = (.fail, "ML-KEM not available")
                }
            case .MLDSA:
                if #available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, macCatalyst 26.0, visionOS 26.0, *) {
                    (status, message) = try testMLDSA(type: mldsatype)
                } else {
                    (status, message) = (.fail, "ML-DSA not available")
                }
            case .PQHPKE:
                if #available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, macCatalyst 26.0, visionOS 26.0, *) {
                    (status, message) = try testPQHPKE(type: pqhpketype)
                } else {
                    (status, message) = (.fail, "PQ-HPKE not available")
                }
            case .hybridSig:
                if #available(iOS 26.0, macOS 26.0, watchOS 26.0, tvOS 26.0, macCatalyst 26.0, visionOS 26.0, *) {
                    (status, message) = try testHybridSig(type: hybridsigtype)
                } else {
                    (status, message) = (.fail, "Hybrid Signatures not available")
                }
            }
        } catch let error as KeyStoreError {
            (status, message) = (.fail, error.message)
        } catch {
            (status, message) = (.fail, error.localizedDescription)
        }
    }
}
