/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that shows the ticket search result.
*/

import AppIntents
import SwiftUI

struct LandmarkTicketPriceView: View {
    let landmark: LandmarkEntity
    let price: Double
    let numberOfTickets: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            Image(landmark.landmark.backgroundImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(ContainerRelativeShape())

            HStack {
                Text("\(landmark.name)")
                    .font(.title.bold())

                Spacer()

                Image(systemName: "bookmark.circle")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.blue)
                    .contentTransition(.symbolEffect(.replace.magic(fallback: .replace)))
                    .buttonStyle(ScaleButtonStyle())
            }

            Divider()

            HStack(alignment: .top) {

                VStack(alignment: .leading) {
                    Text("General Admission")
                        .font(.headline.bold())
                    Text("04/01/2025")
                        .font(.default)
                }

                Spacer()

                VStack(alignment: .trailing) {

                    Text("\(numberOfTickets) tickets")
                        .font(.callout)
                    Text("$\(price, specifier: "%.2f")")
                        .font(.system(size: 36, weight: .bold))

                    Text("Updated \(Date(), style: .relative) ago")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            Button(intent: ClosestLandmarkIntent()) {
                Text("Book Now \(Image(systemName: "chevron.right"))")
                    .fontWeight(.bold)
                    .font(.title2)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let modelData = ModelData()

    ScrollView {
        LandmarkTicketPriceView(
            landmark: try! modelData.landmarkEntity(id: 1005),
            price: 87.96,
            numberOfTickets: 4
        )
    }
    .padding(10)
}
