/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that provides a button label that aligns its icon and title.
*/

import SwiftUI

/**
 A menu button label that aligns its icon and title.
 */
struct ButtonLabel: View {
    struct WatchMenuLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            HStack {
                configuration.icon
                    .frame(width: 30)
                configuration.title
                Spacer()
            }
        }
    }
    
    struct VerticalIconTitleLabelStyle: LabelStyle {
        func makeBody(configuration: Configuration) -> some View {
            VStack {
                Spacer()
                configuration.icon
                    .frame(width: 30)
                configuration.title
                    .frame(minWidth: 60)
                Spacer()
            }
        }
    }
    
    let title: String
    let systemImage: String
    
    var body: some View {
        #if os(watchOS)
        Label(title, systemImage: systemImage)
            .labelStyle(WatchMenuLabelStyle())
        #else
        Label(title, systemImage: systemImage)
            .labelStyle(VerticalIconTitleLabelStyle())
        #endif
    }
}
