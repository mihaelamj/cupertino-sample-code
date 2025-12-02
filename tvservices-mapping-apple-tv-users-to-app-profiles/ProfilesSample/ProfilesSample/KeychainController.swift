/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class to access the user-independent keychain that all accounts on the device can access.
*/

import Foundation

class KeychainController {
    private(set) var credentials: (username: String, password: String)?

    private let baseQuery: [CFString: Any]

    init() {
        var baseQuery: [CFString: Any] = [
            kSecAttrService: "com.example.apple-samplecode.ProfilesSample",
            kSecClass: kSecClassGenericPassword
        ]
        if #available(tvOS 16.0, *) {
            baseQuery[kSecUseUserIndependentKeychain] = kCFBooleanTrue as AnyObject
        }
        self.baseQuery = baseQuery

        loadCredentials()
    }

    func save(username: String, password: String) {
        guard let passwordData = password.data(using: .utf8) else {
            return
        }

        let attributes: [CFString: Any] = [
            kSecAttrAccount: username,
            kSecValueData: passwordData
        ]

        var status: OSStatus = errSecCoreFoundationUnknown
        var itemExists = SecItemCopyMatching(baseQuery as CFDictionary, nil) == errSecSuccess

        // Try to add the item to the keychain first.
        if !itemExists {
            let addAttributes = baseQuery.merging(attributes) { (current, _) in current }
            status = SecItemAdd(addAttributes as CFDictionary, nil)
            itemExists = status == errSecDuplicateItem
        }

        // Otherwise, update if it already exists.
        if itemExists {
            status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        }

        guard status == errSecSuccess else {
            return
        }

        credentials = (username, password)
    }

    func removeCredentials() {
        SecItemDelete(baseQuery as CFDictionary)
        credentials = nil
    }

    private func loadCredentials() {
        var attributesQuery = baseQuery
        attributesQuery[kSecReturnAttributes] = kCFBooleanTrue

        // Read all attributes. This is where the username comes from.
        var outAttributes: AnyObject?
        guard SecItemCopyMatching(attributesQuery as CFDictionary, &outAttributes) == errSecSuccess,
              let attributes = outAttributes as? [CFString: Any] else {
            return
        }

        // This is where the password comes from.
        var passwordQuery = baseQuery
        passwordQuery[kSecAttrAccount] = attributes[kSecAttrAccount]
        passwordQuery[kSecReturnData] = kCFBooleanTrue

        var outPassword: AnyObject?
        guard SecItemCopyMatching(passwordQuery as CFDictionary, &outPassword) == errSecSuccess,
              let passwordData = outPassword as? Data else {
            return
        }

        if let username = attributes[kSecAttrAccount] as? String,
            let password = String(data: passwordData, encoding: .utf8) {
            credentials = (username: username, password: password)
        }
    }
}
