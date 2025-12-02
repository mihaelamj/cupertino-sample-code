/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that mimics asynchronous lookups of contacts.
*/

public class ContactLookup {

    public var contacts = Contact.sampleContacts

    public init() {}

    public func lookup(displayName: String, completion: (_ contacts: [Contact]) -> Void) {
        // This sample searches through a local array of contacts but this could
        // equally be an asynchronous call to a remote server.
        let nameFormatter = PersonNameComponentsFormatter()

        let matchingContacts = contacts.filter { contact in
            nameFormatter.style = .medium
            if nameFormatter.string(from: contact.nameComponents) == displayName {
                return true
            }

            nameFormatter.style = .short
            if nameFormatter.string(from: contact.nameComponents) == displayName {
                return true
            }

            return false
        }

        completion(matchingContacts)
    }

    public func lookup(emailAddress: String, completion: (_ contact: Contact?) -> Void) {
        // This sample searches through a local array of contacts but this could
        // equally be an asynchronous call to a remote server.
        if let contact = contacts.first(where: { $0.emailAddress == emailAddress }) {
            completion(contact)
            return
        }

        completion(nil)
    }
}
