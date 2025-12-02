/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A mechanism for demonstrating that all the different CryptoKit key types can be stored in the keychain.
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
        case nist = "NIST Keys"
        case curve = "Curve Keys"
        case symmetric = "Symmetric Keys"
    }
    
    /// Tasks for which asymmetric keys can be used.
    enum Purpose: String, CaseIterable {
        case signing = "Signing"
        case keyAgreement = "Key Agreement"
    }
    
    /// NIST key types.
    enum NISTSize: String, CaseIterable {
        case p256 = "P-256"
        case p384 = "P-384"
        case p521 = "P-521"
    }
    
    /// Symmetric key sizes.
    enum SymmetricSize: String, CaseIterable {
        case bits128 = "128"
        case bits192 = "192"
        case bits256 = "256"
    }

    /// The kind of key to test.
    var category = Category.nist {
        didSet {
            reset()
        }
    }
    
    /// The kind of NIST key to test, when applicable.
    var nistSize = NISTSize.p256 {
        didSet {
            reset()
            useSecureEnclave = false
        }
    }
    
    /// A Boolean indicating whether to use a Secure Enclave key.
    @Published var useSecureEnclave = false {
        didSet {
            reset()
        }
    }
    
    /// An indicator of whether the current hardware supports Secure Enclave.
    var disableSecureEnclave: Bool {
        !SecureEnclave.isAvailable
    }
    
    /// The kind of assymetric key to test, when applicable.
    var purpose = Purpose.signing {
        didSet {
            reset()
        }
    }
    
    /// The size of symmetric key to test, when applicable.
    var bits = SymmetricSize.bits256 {
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
            case .nist:
                if useSecureEnclave {
                    (status, message) = try testSecureEnclave(purpose: purpose)
                } else {
                    (status, message) = try testNIST(size: nistSize, purpose: purpose)
                }
            case .curve:
                (status, message) = try testCurve(purpose: purpose)
            case .symmetric:
                (status, message) = try testSymmetric(bits: bits)
            }
        } catch let error as KeyStoreError {
            (status, message) = (.fail, error.message)
        } catch {
            (status, message) = (.fail, error.localizedDescription)
        }
    }
}
