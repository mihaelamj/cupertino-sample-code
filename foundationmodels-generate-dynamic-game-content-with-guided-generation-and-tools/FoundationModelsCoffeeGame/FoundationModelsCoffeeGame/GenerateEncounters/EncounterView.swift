/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a randomly generated customer with controls to make their drink order.
*/

import SwiftUI

struct EncounterView: View {
    @Environment(\.dismiss) var dismiss

    @State var encounterEngine = EncounterEngine()
    @State var feedbackDialog: String?
    @State var processing: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical) {
                HStack {
                    Spacer()
                    exitButton
                }
                .padding()
                
                if let character = encounterEngine.customer {
                    CustomerProfileView(customer: character)
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "cloud.fill")
                            .foregroundStyle(.white)
                        Image(systemName: "cup.and.saucer.fill")
                            .foregroundStyle(.brown)
                        Image(systemName: "cloud.fill")
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    if let feedbackDialog {
                        Text(AttributedString(feedbackDialog))
                            .modifier(GameBoxStyle())
                    } else if processing {
                        ProgressView()
                    } else {
                        CoffeeOrderView { drink in
                            processing = true
                            Task {
                                feedbackDialog = await encounterEngine.judgeDrink(drink: drink)
                                processing = false
                            }
                        }
                    }
                } else {
                    ProgressView()
                }
            }
        }
    }
    
    @ViewBuilder
    var exitButton: some View {
        Button {
            // dismiss modal
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .fontWeight(.bold)
                .foregroundStyle(.darkBrown)
                .font(.title2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EncounterView()
}
