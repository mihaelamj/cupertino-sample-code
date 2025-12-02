/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Displays the contact list retrieved from the document.
*/

import Vision
import SwiftUI

struct ContactView: View {
    let contacts: [Contact]
    var body: some View {
        Text("Contacts")
        List(contacts, id: \.name) { contact in
            HStack {
                Text(contact.name)
                Spacer()
                Text(contact.email)
                Spacer()
                Text(contact.phoneNumber ?? "")
            }
        }
    }
}
