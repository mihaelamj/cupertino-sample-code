/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main SwiftUI view for SpeakerBox's Watch App
*/

import SwiftUI

struct ContentView: View {
    
    var incomingCallback : (_ : String, _ : Bool) -> Void
        
    var body: some View {
        
        Button("Incoming Call") {
            print("Pressed Incoming Call")
            incomingCallback("1234567890", false)
        }
        
        .padding()
        
        Button("Outgoing Call") {
            print("Pressed Outgoing Call")
                        
            SpeakerboxCallManager().startCall(handle: "1234567890", video: false)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(incomingCallback: { (handle: String, video: Bool) in
            
        })
    }
}
