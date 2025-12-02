/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The interactive view that changes the number of tickets for the ticket search.
*/

import AppIntents
import SwiftUI

struct TicketRequestView: View {
    let searchRequest: SearchRequestEntity

    private var numberOfGuests: Int {
        searchRequest.numberOfGuests
    }

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Text("How many tickets?")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            HStack {
                Button(intent: ConfigureGuestsIntent(searchRequest: searchRequest, numberOfGuests: max(1, numberOfGuests - 1))) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(numberOfGuests <= 1 ? .gray : .red)
                }
                .disabled(numberOfGuests <= 1)
                .buttonStyle(ScaleButtonStyle())

                Text("\(numberOfGuests)")
                    .font(.system(size: 48, weight: .bold))
                    .frame(minWidth: 60)
                    .contentTransition(.numericText())

                Button(intent: ConfigureGuestsIntent(searchRequest: searchRequest, numberOfGuests: max(1, numberOfGuests + 1))) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.bottom, 12)
    }
}

#Preview {
    let modelData = ModelData()

    ScrollView {
        TicketRequestView(
            searchRequest: .init(
                id: UUID().uuidString,
                landmark: try! modelData.landmarkEntity(id: 1005),
                numberOfGuests: 5,
                status: .pending,
                finalPrice: nil
            )
        )
    }
    .padding(10)
}
