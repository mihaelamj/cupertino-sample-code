/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Contact Card object implements the NSItemProviderReading and NSItemProviderWriting protocols
to read and write vCards/Plain Text.
*/

import UIKit
import Contacts // for CNContactVCardSerialization
import MobileCoreServices // for kUTTypeVCard, kUTTypeUTF8PlainText

enum ContactCardError: Error {
    case invalidTypeIdentifier
    case invalidVCard
}

/// - Tag: ContactCard
final class ContactCard: NSObject, NSItemProviderReading, NSItemProviderWriting {

    var name: String
    var phoneNumber: String?
    var photo: UIImage?

	// MARK: - Initialization

	init(name: String, phone: String? = nil, picture: UIImage? = nil) {
        self.name = name
        phoneNumber = phone
        photo = picture
        super.init()
    }

	// MARK: - NSItemProviderReading

	static var readableTypeIdentifiersForItemProvider =
		[kUTTypeVCard as String, kUTTypeUTF8PlainText as String]

    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> ContactCard {
        let newContact = ContactCard(name: "")
        if typeIdentifier == kUTTypeVCard as String {
            let contacts = try CNContactVCardSerialization.contacts(with: data)
            if let contact = contacts.first {
                newContact.name = contact.givenName + " " + contact.familyName
                newContact.phoneNumber = contact.phoneNumbers.first?.value.stringValue
                if let photoData = contact.imageData {
                    newContact.photo = UIImage(data: photoData)
                }
            } else {
                throw ContactCardError.invalidVCard
            }
        } else if typeIdentifier == kUTTypeUTF8PlainText as String {
            newContact.name = String(data: data, encoding: .utf8)!
        } else {
            throw ContactCardError.invalidTypeIdentifier
        }
        return newContact
    }

	// MARK: - NSItemProviderWriting

	static var writableTypeIdentifiersForItemProvider: [String] = [kUTTypeVCard as String, kUTTypeUTF8PlainText as String]

    func loadData(withTypeIdentifier typeIdentifier: String,
                  forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
		if typeIdentifier == kUTTypeVCard as String {
			completionHandler(createVCard(), nil)
		} else if typeIdentifier == kUTTypeUTF8PlainText as String {
			completionHandler(name.data(using: .utf8), nil)
		} else {
			completionHandler(nil, ContactCardError.invalidTypeIdentifier)
		}
        return nil
    }

	// MARK: - vCard Creation

    func createVCard() -> Data? {
        var vCardText = "BEGIN:VCARD\nVERSION:3.0"
        vCardText += "\nFN:\(name)"

        if let phoneNumber = phoneNumber {
            vCardText += "\nTEL;type=pref:\(phoneNumber)"
        }

        if let photo = photo, let pngData = photo.pngData() {
            let base64String = pngData.base64EncodedString()
            vCardText += "\nPHOTO;ENCODING=BASE64;TYPE=PNG:\(base64String)"
        }

        vCardText.append("\nEND:VCARD")
        return vCardText.data(using: .utf8)
    }
}
