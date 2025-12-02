/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
BackyardVisitorsWidget views.
*/

import WidgetKit
import SwiftUI
import BackyardBirdsUI
import BackyardBirdsData
import LayeredArtworkLibrary
import SwiftData
import OSLog

struct CircularBackyardView: View {
    var entry: SimpleEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let bird = entry.bird {
                ComposedBird(bird: bird)
                    .scaledToFit()
                    .widgetAccentable()
                    .padding()
            } else {
                Image(.fountainFill)
                    .foregroundStyle(entry.backyard.backgroundColor)
                    .imageScale(.large)
                    .scaledToFit()
                    .widgetAccentable()
            }
        }
    }
}

struct CornerBackgroundView: View {
    var entry: SimpleEntry
    
    var body: some View {
        if let bird = entry.bird {
            ComposedBird(bird: bird)
                .scaledToFit()
                .widgetAccentable()
                .widgetLabel {
                    Text(bird.speciesName)
                }
        } else {
            Text("No Bird")
                .widgetCurvesContent()
                .widgetLabel {
                    Text(entry.backyard.name)
                }
        }
    }
}

struct InlineBackgroundView: View {
    var entry: SimpleEntry
    
    var body: some View {
        if let bird = entry.bird {
            Text(bird.speciesName)
                .widgetAccentable()
        } else {
            Text(entry.backyard.name)
                .widgetAccentable()
        }
    }
}
