/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a randomly generated customer's profile picture, name, and dialog
*/

import SwiftUI

struct CustomerProfileView: View {
    var customer: NPC

    var body: some View {
        HStack(alignment: .top) {
            // The customer's generated profile picture
            ZStack {
                if let image = customer.picture.image {
                    #if canImport(UIKit)
                    Image(uiImage: UIImage(cgImage: image)).resizable()
                        .accessibilityLabel(customer.picture.imageDescription)
                    #elseif canImport(AppKit)
                    Image(
                        nsImage: NSImage(
                            cgImage: image,
                            size: NSSize(width: image.width, height: image.height)
                        )
                    )
                    .resizable()
                    .accessibilityLabel(customer.picture.imageDescription)
                    #endif
                }
                if customer.picture.isResponding {
                    ProgressView()
                }
            }
            .aspectRatio(contentMode: .fit)
            .frame(width: 200, height: 200)

            VStack(alignment: .leading) {
                // The customer's generated name
                LabeledContent("Name:", value: customer.name)
                    .font(.headline)
                    .foregroundStyle(.darkBrown)

                // The customer's generated dialog
                Text(AttributedString(customer.coffeeOrder))
                    .padding(.top)
                    .frame(height: 100)

            }.padding()
        }
        .modifier(GameBoxStyle())
    }
}
