/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An entry in the domain list.
*/

import SwiftUI
import FileProvider

struct DomainListEntry: View {
    let domain: NSFileProviderDomain
    let selected: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(domain.displayName).foregroundColor(selected ? .white : .black)
                if domain.userEnabled {
                    Text("Enabled").font(.subheadline).foregroundColor(selected ? .white : .gray)
                } else {
                    Text("Disabled").font(.subheadline).foregroundColor(selected ? .white : .red)
                }
            }
            Spacer()
        }
    }
}
