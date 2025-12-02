/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A struct that defines a contact that can receive payments from our app.
*/

import Intents

public struct Contact {

    private static let nameFormatter = PersonNameComponentsFormatter()
    public let nameComponents: PersonNameComponents
    public let emailAddress: String

    public var formattedName: String {
        return Contact.nameFormatter.string(from: nameComponents)
    }

    public init(givenName: String?, familyName: String?, emailAddress: String) {
        var nameComponents = PersonNameComponents()
        nameComponents.givenName = givenName
        nameComponents.familyName = familyName

        self.nameComponents = nameComponents
        self.emailAddress = emailAddress
    }

}

extension Contact: Equatable {}

extension Contact: Codable {}

/// Extend `Contact` with some sample contact data.

public extension Contact {

    static let sampleContacts = [
        Contact(givenName: "John", familyName: "Doe", emailAddress: "johndoe@example.com"),
        Contact(givenName: "Jane", familyName: "Doe", emailAddress: "janedoe@example.com")
    ]

}
