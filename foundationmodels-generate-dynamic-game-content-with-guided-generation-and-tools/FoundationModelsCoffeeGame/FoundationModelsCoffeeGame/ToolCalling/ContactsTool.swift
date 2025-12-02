/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Use the player's personal contacts to personalize NPCs to a certain generation.
*/

import Contacts
import FoundationModels

struct ContactsTool: Tool {

    let name = "getContacts"

    let description = """
        Get a contact born in this month. \
        Today is \(Date().formatted(date: .complete, time: .omitted))
        """

    let defaultName = "Naomi"

    @Generable
    struct Arguments {
        let month: Int
    }

    func call(arguments: Arguments) async -> String {
        do {
            // Request permission to access the person's contacts.
            let store = CNContactStore()
            try await store.requestAccess(for: .contacts)

            let keysToFetch = [CNContactGivenNameKey, CNContactBirthdayKey] as [CNKeyDescriptor]
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)

            // Fetch a list of contacts with a birthday within the range that the
            // model specifies in the arguments.
            var contacts: [CNContact] = []
            try store.enumerateContacts(with: request) { contact, stop in
                if let month = contact.birthday?.month {
                    if arguments.month == month {
                        contacts.append(contact)
                    }
                }
            }
            guard let pickedContact = contacts.shuffled().first else {
                Logging.general.log("Contact Tool: No contact found")
                return defaultName
            }
            Logging.general.log("Contact Tool: found contact \(pickedContact.givenName)")
            return pickedContact.givenName
        } catch {
            Logging.general.log("Toolcalling error with accessing player's contacts: \(error)")
            return defaultName
        }
    }
}

@Generable
enum Generation {
    case babyBoomers
    case genX
    case millennial
    case genZ

    var yearRange: ClosedRange<Int> {
        switch self {
        case .babyBoomers:
            return 1946...1964
        case .genX:
            return 1965...1980
        case .millennial:
            return 1981...1996
        case .genZ:
            return 1997...2010
        }
    }
}
