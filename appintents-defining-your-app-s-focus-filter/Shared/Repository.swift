/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A repository class that handles storing a data model into user defaults.
*/

import OSLog
import AppIntents

/// - Tag: Repository
final class Repository: Sendable {
    enum RepositoryError: Error, CustomLocalizedStringResourceConvertible {
        case notFound
        
        var localizedStringResource: LocalizedStringResource {
            switch self {
            case .notFound: return "Element not found"
            }
        }
    }
    
    static let shared = Repository()

    static var suiteUserDefaults = UserDefaults(suiteName: "group.exampleChatApp")!
    
    func updateAppDataModelStore(_ appDataModel: AppDataModel) {
        let encoder = JSONEncoder()
        do {
            let appDataModelEncoded = try encoder.encode(appDataModel)
            Self.suiteUserDefaults.set(appDataModelEncoded, forKey: "AppData")
            logger.debug("Stored app data model")
        } catch {
            logger.error("Failed to encode app data model \(error.localizedDescription)")
        }
    }

    var accountsLoggedIn: [AccountEntity] {
        Array(AccountEntity.exampleAccounts.values)
    }
    
    func accountEntity(identifier: String) throws -> AccountEntity {
        guard let account = AccountEntity.exampleAccounts[identifier] else {
            throw RepositoryError.notFound
        }
        return account
    }
}

extension Repository {
    var logger: Logger {
        let subsystem = Bundle.main.bundleIdentifier!
        return Logger(subsystem: subsystem, category: "Repository")
    }
}
