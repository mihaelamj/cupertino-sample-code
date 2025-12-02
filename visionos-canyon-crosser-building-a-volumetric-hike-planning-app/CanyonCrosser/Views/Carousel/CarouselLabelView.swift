/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A label that displays the selected landmark name.
*/

import SwiftUI

struct CarouselLabelView: View {
    @Environment(CarouselModel.self) private var carouselModel

    var body: some View {
        ZStack {
            HiddenLabelText(carouselItems: carouselModel.items)
            CarouselLabelText(
                name: carouselModel.selectedItem.name,
                country: carouselModel.selectedItem.country
            )
        }
        .padding(20)
        .padding(.horizontal, 40)
        .glassBackgroundEffect(in: .capsule)
        .animation(.easeInOut, value: carouselModel.selectedItem)
    }
}

#Preview {
    CarouselLabelView()
        .environment(CarouselModel())
}

/// A view that shows the name and country of the selected item.
private struct CarouselLabelText: View {
    let name: String
    let country: String
    
    var body: some View {
        VStack {
            Text(name)
                .font(.largeTitle)
            Text(country)
                .font(.title)
                .foregroundStyle(.secondary)
        }
    }
}

/// A hidden view to prevent resizing.
private struct HiddenLabelText: View {
    let carouselItems: [CarouselItem]
    
    var body: some View {
        ForEach(carouselItems) { carouselItem in
            CarouselLabelText(
                name: carouselItem.name,
                country: carouselItem.country
            )
        }
        .hidden()
    }
}
