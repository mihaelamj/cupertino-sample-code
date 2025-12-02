/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An entity query that Focus filters or Shortcuts use to suggest or find entity objects.
*/

import AppIntents

/// - Tag: AccountEntityQuery
struct AccountEntityQuery: EntityQuery {
    func entities(for identifiers: [AccountEntity.ID]) async throws -> [AccountEntity] {
        Repository.shared.accountsLoggedIn.filter {
            identifiers.contains($0.id)
        }
    }
    
    func suggestedEntities() async throws -> [AccountEntity] {
        Repository.shared.accountsLoggedIn
    }
}
