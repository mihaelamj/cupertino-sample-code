/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows the workout metrics in a widget.
*/

import SwiftUI
import WidgetKit

struct LiveActivityView: View {
    @Environment(\.redactionReasons) var redactionReasons
    
    var context: ActivityViewContext<WorkoutWidgetAttributes>
    var body: some View {
        let metrics = context.state.metrics
        
        VStack {
            HStack(alignment: .lastTextBaseline) {
                Image(systemName: context.attributes.symbol)
                    .font(.system(size: 45))
                    .foregroundColor(.accent)
                    .padding(.trailing)
                ElapsedTimeView(elapsedTime: context.state.metrics.elapsedTime)
                    .font(.system(size: 45))
            }
            if metrics.activeEnergy != nil {
                HStack {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 25))
                        
                        Text(redactionReasons.contains(.privacy) ? "--" : metrics.getHeartRate())
                            .font(.system(size: 25))
                    }
                    if metrics.supportsDistance {
                        HStack {
                            Image(systemName: "lines.measurement.horizontal")
                                .foregroundColor(.green)
                                .font(.system(size: 25))
                                .padding(.leading)
                            Text(redactionReasons.contains(.privacy) ? "--" : metrics.getDistance())
                                .font(.system(size: 25))
                        }
                    }
                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.purple)
                            .font(.system(size: 25))
                            .padding(.leading)
                        Text(redactionReasons.contains(.privacy) ? "--" : metrics.getActiveEnergy())
                    }
                }
                .padding(.top)
            }
        }
    }
}
