/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Tutorial page view base implementation for the help page.
*/

import SwiftUI

struct Section: Identifiable {
    let id = UUID()
    let title: String
    let body: [String]
    let symbol: String?
    let symbolColor: Color?
}

struct TutorialPageView: View {
    let pageName: String
    let imageName: String
    let imageCaption: String
    let sections: [Section]

    var body: some View {
        VStack(alignment: .leading) {
            Text(pageName)
                .foregroundColor(.primary)
                .font(.largeTitle)
                .bold()
            Text(imageCaption)
                .foregroundColor(.secondary)
            HStack {
                Spacer()
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(UIDevice.current.userInterfaceIdiom == .pad ? 1.5 : 1.2)
                Spacer()
            }

            SectionView(sections: sections)
        }
        .navigationBarTitle(pageName, displayMode: .inline)
    }
}

private struct SectionView: View {
    let sections: [Section]

    private let sectionHeight = 120.0

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(sections) { section in
                VStack(alignment: .leading) {
                    Divider()
                        .padding([.bottom, .trailing], 5.0)

                    HStack {
                        Text(section.title)
                            .bold()

                        Spacer()

                        if let symbol = section.symbol, let symbolColor = section.symbolColor {
                            Text(Image(systemName: symbol))
                                .bold()
                                .foregroundColor(symbolColor)
                        }
                    }

                    ForEach(section.body, id: \.self) { line in
                        Text(line)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }
                .frame(height: sectionHeight)
            }
        }

        Spacer()
    }
}
