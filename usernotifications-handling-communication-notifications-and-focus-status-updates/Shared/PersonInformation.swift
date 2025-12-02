/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data model containing essential information to suggest a person.
*/

import Foundation

enum AvatarImage {
    // The system looks for a file with the specified name in the app's or extension's bundle.
    case imageName(String)
    // Data from an image file or remotely downloaded.
    case imageData(Data)
    // The SF Symbol name.
    case systemImageNamed(String)
}

enum PersonName {
    case displayName(String)
    case nameComponents(givenName: String, familyName: String)
}

enum UniqueUserIdentifier {
    /// The user's social profile handle. Use an identifier that won't change over time.
    /// Once matched with a contact, it must not change to ensure breakthough.
    case socialProfile(String)
    /// The user's phone number.
    case phoneNumber(String)
    /// The user's email address.
    case emailAddress(String)
}

struct PersonInformation {
    let name: PersonName
    let userIdentifier: UniqueUserIdentifier
    let contactIdentifier: String?
    let avatarImage: AvatarImage?
    let isCurrentUser: Bool
}

extension PersonInformation {
    static func currentUserSocialProfile() -> Self {
        PersonInformation(name: .displayName("Bailey Cavanna"),
                          userIdentifier: .socialProfile("@baileyCavanna"),
                          contactIdentifier: nil,
                          avatarImage: nil,
                          isCurrentUser: true)
    }
    
    static func exampleSocialProfile(avatarImage: AvatarImage) -> Self {
        PersonInformation(name: .nameComponents(givenName: "Karina", familyName: "Cavanna"),
                          userIdentifier: .socialProfile("@karinaCavanna"),
                          contactIdentifier: nil,
                          avatarImage: avatarImage,
                          isCurrentUser: false)
    }
    
    static func examplePhoneNumber(avatarImage: AvatarImage) -> Self {
        PersonInformation(name: .displayName("Michael Cavanna"),
                          userIdentifier: .phoneNumber("1-202-555-0156"),
                          contactIdentifier: nil,
                          avatarImage: avatarImage,
                          isCurrentUser: false)
    }
    
    static func exampleEmailAddress(avatarImage: AvatarImage) -> Self {
        PersonInformation(name: .displayName("Jesse Cavanna"),
                          userIdentifier: .emailAddress("jesse@domain.com"),
                          contactIdentifier: nil,
                          avatarImage: avatarImage,
                          isCurrentUser: false)
    }
    
    static func examplePhoneWithContactId(_ contactIdentifier: String,
                                          avatarImage: AvatarImage) -> Self {
        PersonInformation(name: .displayName("Marisa Cavanna"),
                          userIdentifier: .phoneNumber("1-202-555-0148"),
                          contactIdentifier: contactIdentifier,
                          avatarImage: avatarImage,
                          isCurrentUser: false)
    }
}
