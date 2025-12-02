/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A message view.
*/

import SwiftUI

enum Message: Hashable, Identifiable {
     var id: Self { return self }
    
    case none
    case events
    case lessons
    case lessonSlots
    case denied
    case restricted
    case upgrade
    
    var localizedName: LocalizedStringKey {
        switch self {
            case .none:
                return ""
            case .events:
                return "No Events"
            case .lessons:
                return "Couldn't load lessons."
            case .lessonSlots:
                return "No lesson slots today!"
            case .denied:
            return "The app doesn't have permission to access calendar events. Please grant the app access to Calendar in Settings."
            case .restricted:
            return "This device doesn't allow access to calendar events. Please update the permission in Settings."
            case .upgrade:
                let access = "The app has write-only access to Calendar in Settings."
                let update = "Please grant it full access so the app can fetch and delete your events."
                return "\(access) \(update)"
        }
    }
}

struct MessageView: View {
    var message: Message
    
    init(message: Message) {
        self.message = message
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(message.localizedName)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.primary)
                .padding()
        }
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(message: .none)
        MessageView(message: .events)
        MessageView(message: .lessons)
        MessageView(message: .lessonSlots)
    }
}
