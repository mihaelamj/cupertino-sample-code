/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the tracking summary information for a DockKit session.
*/

import SwiftUI
#if canImport(DockKit)
import DockKit
#endif

/// A view that displays the tracking summary information for a DockKit session.
struct TrackingSummaryView: View {
    @Binding var trackedPersons: [DockAccessoryTrackedPerson]
    
    var body: some View {
        ForEach(trackedPersons) { person in
            ZStack {
                Rectangle()
                    .fill(.clear)
                    .border(person.saliency == nil ? Color.white : Color.green, width: 2)
                    .frame(width: person.rect.width, height: person.rect.height)
                    .position(x: person.rect.midX, y: person.rect.midY)
                HStack(alignment: .top) {
                    VStack {
                        Image(systemName: "checkmark.circle")
                        Image(systemName: "speaker.wave.1")
                        Image(systemName: "eye")
                    }
                    VStack(alignment: .leading) {
                        Text("\(person.saliency ?? -1)")
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.clear)
                                .stroke(Color.white, lineWidth: 1)
                                .frame(width: 50)
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 50 * (person.speaking ?? 0.0))
                        }
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.clear)
                                .stroke(Color.white, lineWidth: 1)
                                .frame(width: 50)
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: 50 * (person.looking ?? 0.0))
                            
                        }
                    }
                }
                .frame(width: 50, height: 50)
                .position(x: person.rect.midX, y: person.rect.maxY + 25)
            }
        }
    }
}

#if !targetEnvironment(simulator)
extension DockAccessory.TrackedPerson : @retroactive Identifiable {
    public var id: UUID {
        return UUID()
    }
}

#Preview {
    TrackingSummaryView(trackedPersons: .constant([]))
}
#endif
