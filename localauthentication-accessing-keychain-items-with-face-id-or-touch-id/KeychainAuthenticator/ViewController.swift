/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller.
*/

import UIKit
import LocalAuthentication

class ViewController: UIViewController {

    /// A text label used to show the result of an operation.
    @IBOutlet weak var statusLabel: UILabel!

    /// The username and password that we want to store or read.
    struct Credentials {
        var username: String
        var password: String
    }

    /// The server we are accessing with the credentials.
    let server = "www.example.com"

    /// Keychain errors we might encounter.
    struct KeychainError: Error {
        var status: OSStatus

        var localizedDescription: String {
            return SecCopyErrorMessageString(status, nil) as String? ?? "Unknown error."
        }
    }

    // MARK: - Actions

    @IBAction func tapAdd(_ sender: Any) {
        // Normally, username and password would come from the user interface.
        let credentials = Credentials(username: "appleseed", password: "1234")

        do {
            try addCredentials(credentials, server: server)
            show(status: "Added credentials.")
        } catch {
            if let error = error as? KeychainError {
                show(status: error.localizedDescription)
            }
        }
    }

    @IBAction func tapRead(_ sender: Any) {
        do {
            let credentials = try readCredentials(server: server)
            show(status: "Read credentials: \(credentials.username)/\(credentials.password)")
        } catch {
            if let error = error as? KeychainError {
                show(status: error.localizedDescription)
            }
        }
    }

    @IBAction func tapDelete(_ sender: Any) {
        do {
            try deleteCredentials(server: server)
            show(status: "Deleted credentials.")
        } catch {
            if let error = error as? KeychainError {
                show(status: error.localizedDescription)
            }
        }
    }

    /// Draws the status string on the screen, including a partial fade out.
    func show(status: String) {
        statusLabel.alpha = 1
        statusLabel.text = status
        UIView.animate(withDuration: 0.5, delay: 1, options: [], animations: { self.statusLabel.alpha = 0.3 }, completion: nil)
    }

    // MARK: - Keychain Access

    /// Stores credentials for the given server.
    func addCredentials(_ credentials: Credentials, server: String) throws {
        // Use the username as the account, and get the password as data.
        let account = credentials.username
        let password = credentials.password.data(using: String.Encoding.utf8)!

        // Create an access control instance that dictates how the item can be read later.
        let access = SecAccessControlCreateWithFlags(nil, // Use the default allocator.
                                                     kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                                     .userPresence,
                                                     nil) // Ignore any error.

        // Allow a device unlock in the last 10 seconds to be used to get at keychain items.
        let context = LAContext()
        context.touchIDAuthenticationAllowableReuseDuration = 10

        // Build the query for use in the add operation.
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: account,
                                    kSecAttrServer as String: server,
                                    kSecAttrAccessControl as String: access as Any,
                                    kSecUseAuthenticationContext as String: context,
                                    kSecValueData as String: password]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }

    /// Reads the stored credentials for the given server.
    func readCredentials(server: String) throws -> Credentials {
        let context = LAContext()
        context.localizedReason = "Access your password on the keychain"
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecUseAuthenticationContext as String: context,
                                    kSecReturnData as String: true]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else { throw KeychainError(status: status) }

        guard let existingItem = item as? [String: Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: String.Encoding.utf8),
            let account = existingItem[kSecAttrAccount as String] as? String
            else {
                throw KeychainError(status: errSecInternalError)
        }

        return Credentials(username: account, password: password)
    }

    /// Deletes credentials for the given server.
    func deleteCredentials(server: String) throws {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: server]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else { throw KeychainError(status: status) }
    }
}

