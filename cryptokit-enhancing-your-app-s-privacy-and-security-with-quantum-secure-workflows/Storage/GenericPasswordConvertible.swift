/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The interface required for conversion to a generic password keychain item.
*/

import Foundation
import CryptoKit

/// The interface needed for `SecKey` conversion.
protocol GenericPasswordConvertible: CustomStringConvertible {
    /// Creates a key from a `SecKey` representation.
    init<D>(secKeyRepresentation data: D) throws where D: ContiguousBytes

    /// A `SecKey` representation of the key.
    var secKeyRepresentation: SymmetricKey { get }
}

extension GenericPasswordConvertible {
    /// A string version of the key for visual inspection.
    /// Important: Never log the actual key data.
    public var description: String {
        return self.secKeyRepresentation.withUnsafeBytes { bytes in
            return "Key representation contains \(bytes.count) bytes."
        }
    }
}

// Declare that the Curve25519 keys are generic passord-convertible.
extension Curve25519.KeyAgreement.PrivateKey: GenericPasswordConvertible, @retroactive CustomStringConvertible {
    init<D>(secKeyRepresentation data: D) throws where D: ContiguousBytes {
        try self.init(rawRepresentation: data)
    }

    var secKeyRepresentation: SymmetricKey {
        self.rawRepresentation.withUnsafeBytes {
            SymmetricKey(data: $0)
        }
    }
}
extension Curve25519.Signing.PrivateKey: GenericPasswordConvertible, @retroactive CustomStringConvertible {
    init<D>(secKeyRepresentation data: D) throws where D: ContiguousBytes {
        try self.init(rawRepresentation: data)
    }

    var secKeyRepresentation: SymmetricKey {
        self.rawRepresentation.withUnsafeBytes {
            SymmetricKey(data: $0)
        }
    }
}

// Ensure that `SymmetricKey` is generic password-convertible.
extension SymmetricKey: GenericPasswordConvertible, @retroactive CustomStringConvertible {
    init<D>(secKeyRepresentation data: D) throws where D: ContiguousBytes {
        self.init(data: data)
    }
    
    var secKeyRepresentation: SymmetricKey {
        return self
    }
}

// Ensure that the ML-KEM keys are generic password-convertible.
@available(iOS 19.0, macOS 16.0, watchOS 12.0, tvOS 19.0, macCatalyst 19.0, visionOS 3.0, *)
extension MLKEM768.PrivateKey: GenericPasswordConvertible, @retroactive CustomStringConvertible {
    init<D>(secKeyRepresentation data: D) throws where D: ContiguousBytes {
        try self.init(integrityCheckedRepresentation: data.withUnsafeBytes { Data($0) })
    }

    var secKeyRepresentation: SymmetricKey {
        return SymmetricKey(data: integrityCheckedRepresentation)
    }
}

@available(iOS 19.0, macOS 16.0, watchOS 12.0, tvOS 19.0, macCatalyst 19.0, visionOS 3.0, *)
extension MLKEM1024.PrivateKey: GenericPasswordConvertible, @retroactive CustomStringConvertible {
    init<D>(secKeyRepresentation data: D) throws where D: ContiguousBytes {
        try self.init(integrityCheckedRepresentation: data.withUnsafeBytes { Data($0) })
    }

    var secKeyRepresentation: SymmetricKey {
        return SymmetricKey(data: integrityCheckedRepresentation)
    }
}

@available(iOS 19.0, macOS 16.0, watchOS 12.0, tvOS 19.0, macCatalyst 19.0, visionOS 3.0, *)
extension MLDSA65.PrivateKey: GenericPasswordConvertible, @retroactive CustomStringConvertible {
    init<D>(secKeyRepresentation data: D) throws where D: ContiguousBytes {
        try self.init(integrityCheckedRepresentation: data.withUnsafeBytes { Data($0) })
    }

    var secKeyRepresentation: SymmetricKey {
        return SymmetricKey(data: integrityCheckedRepresentation)
    }
}

@available(iOS 19.0, macOS 16.0, watchOS 12.0, tvOS 19.0, macCatalyst 19.0, visionOS 3.0, *)
extension MLDSA87.PrivateKey: GenericPasswordConvertible, @retroactive CustomStringConvertible {
    init<D>(secKeyRepresentation data: D) throws where D: ContiguousBytes {
        try self.init(integrityCheckedRepresentation: data.withUnsafeBytes { Data($0) })
    }

    var secKeyRepresentation: SymmetricKey {
        return SymmetricKey(data: integrityCheckedRepresentation)
    }
}

@available(iOS 19.0, macOS 16.0, watchOS 12.0, tvOS 19.0, macCatalyst 19.0, visionOS 3.0, *)
extension XWingMLKEM768X25519.PrivateKey: GenericPasswordConvertible, @retroactive CustomStringConvertible {
    init<D>(secKeyRepresentation data: D) throws where D: ContiguousBytes {
        try self.init(integrityCheckedRepresentation: data.withUnsafeBytes { Data($0) })
    }

    var secKeyRepresentation: SymmetricKey {
        return SymmetricKey(data: seedRepresentation)
    }
}

// Ensure that the Secure Enclave keys are generic password-convertible.
@available(iOS 19.0, macOS 16.0, watchOS 12.0, tvOS 19.0, macCatalyst 19.0, visionOS 3.0, *)
extension SecureEnclave.MLKEM768.PrivateKey: GenericPasswordConvertible, @retroactive CustomStringConvertible {
    init<D>(secKeyRepresentation data: D) throws where D: ContiguousBytes {
        try self.init(dataRepresentation: data.withUnsafeBytes { Data($0) })
    }

    var secKeyRepresentation: SymmetricKey {
        return SymmetricKey(data: dataRepresentation)
    }
}

@available(iOS 19.0, macOS 16.0, watchOS 12.0, tvOS 19.0, macCatalyst 19.0, visionOS 3.0, *)
extension SecureEnclave.MLKEM1024.PrivateKey: GenericPasswordConvertible, @retroactive CustomStringConvertible {
    init<D>(secKeyRepresentation data: D) throws where D: ContiguousBytes {
        try self.init(dataRepresentation: data.withUnsafeBytes { Data($0) })
    }

    var secKeyRepresentation: SymmetricKey {
        return SymmetricKey(data: dataRepresentation)
    }
}

@available(iOS 19.0, macOS 16.0, watchOS 12.0, tvOS 19.0, macCatalyst 19.0, visionOS 3.0, *)
extension SecureEnclave.MLDSA65.PrivateKey: GenericPasswordConvertible, @retroactive CustomStringConvertible {
    init<D>(secKeyRepresentation data: D) throws where D: ContiguousBytes {
        try self.init(dataRepresentation: data.withUnsafeBytes { Data($0) })
    }

    var secKeyRepresentation: SymmetricKey {
        return SymmetricKey(data: dataRepresentation)
    }
}

@available(iOS 19.0, macOS 16.0, watchOS 12.0, tvOS 19.0, macCatalyst 19.0, visionOS 3.0, *)
extension SecureEnclave.MLDSA87.PrivateKey: GenericPasswordConvertible, @retroactive CustomStringConvertible {
    init<D>(secKeyRepresentation data: D) throws where D: ContiguousBytes {
        try self.init(dataRepresentation: data.withUnsafeBytes { Data($0) })
    }

    var secKeyRepresentation: SymmetricKey {
        return SymmetricKey(data: dataRepresentation)
    }
}

extension SecureEnclave.P256.KeyAgreement.PrivateKey: GenericPasswordConvertible, @retroactive CustomStringConvertible {
    init<D>(secKeyRepresentation data: D) throws where D: ContiguousBytes {
        try self.init(dataRepresentation: data.withUnsafeBytes { Data($0) })
    }
    
    var secKeyRepresentation: SymmetricKey {
        return SymmetricKey(data: dataRepresentation)
    }
}

extension SecureEnclave.P256.Signing.PrivateKey: GenericPasswordConvertible, @retroactive CustomStringConvertible {
    init<D>(secKeyRepresentation data: D) throws where D: ContiguousBytes {
        try self.init(dataRepresentation: data.withUnsafeBytes { Data($0) })
    }
    
    var secKeyRepresentation: SymmetricKey {
        return SymmetricKey(data: dataRepresentation)
    }
}
