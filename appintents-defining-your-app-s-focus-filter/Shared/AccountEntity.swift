/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An app entity data model that represents a chat account in this app.
*/

import AppIntents

/// - Tag: AccountEntity
struct AccountEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "A chat account")
    }
    
    static var defaultQuery = AccountEntityQuery()
    
    let id: String
    let displayName: String
    let displaySubtitle: String
    let image: DisplayRepresentation.Image
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(displayName) account",
                              subtitle: "\(displaySubtitle)",
                              image: image)
    }
    
    static var exampleAccounts: [String: AccountEntity] {
        [
            "work-account-identifier":
            AccountEntity(id: "work-account-identifier",
                          displayName: "Work",
                          displaySubtitle: "Team project communications",
                          image: DisplayRepresentation.Image(systemName: "list.bullet.rectangle.portrait.fill")),
            
            "personal-account-identifier":
            AccountEntity(id: "personal-account-identifier",
                          displayName: "Personal",
                          displaySubtitle: "Friends group chat",
                          image: DisplayRepresentation.Image(systemName: "person.fill")),
            
            "gaming-account-identifier":
            AccountEntity(id: "gaming-account-identifier",
                          displayName: "Gaming",
                          displaySubtitle: "Game lobby",
                          image: DisplayRepresentation.Image(systemName: "gamecontroller.fill"))
        ]
    }
}
