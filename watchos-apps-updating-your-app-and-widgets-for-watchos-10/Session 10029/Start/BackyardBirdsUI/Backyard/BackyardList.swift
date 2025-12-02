/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The backyard list.
*/

import SwiftUI
import SwiftData
import BackyardBirdsData

public struct BackyardList: View {
    @Query(sort: [.init(\.creationDate)])
    private var backyards: [Backyard]
    
    public init() { }
    
    public var body: some View {
        List(backyards) { backyard in
            NavigationLink(value: backyard.id) {
                BackyardViewport(backyard: backyard)
                    .overlay(alignment: .topLeading) {
                        Text(backyard.name)
                            .font(.callout)
                            .scenePadding(.horizontal)
                            .padding(.vertical, 8)
                            .foregroundStyle(Color.primary.shadow(.drop(color: .black.opacity(0.25), radius: 4, y: 1)))
                    }
            }
            .buttonStyle(.borderless)
            .listRowInsets(EdgeInsets())
            .containerShape(.rect(cornerRadius: 10))
        }
        #if os(watchOS)
        .listStyle(.carousel)
        #endif
    }
}

#Preview {
    BackyardList()
}
