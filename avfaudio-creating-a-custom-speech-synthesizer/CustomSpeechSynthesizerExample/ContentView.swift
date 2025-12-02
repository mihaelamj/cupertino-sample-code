/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view of the app.
*/

import AVFoundation
import SwiftUI

struct ContentView: View {
    
    // MARK: - Public Properties
    
    let groupDefaults = UserDefaults(suiteName: "group.com.example.apple.samplecode.CustomSpeechSynthesizerExample")
    
    @State var voices: [String] = []
    @State var voiceName: String = ""
    
    var body: some View {
        VStack {
            HStack {
                TextField("Name", text: $voiceName)
                Button("Add Voice") {
                    voices.append(voiceName)
                    voiceName = ""
                    saveVoicesToGroupDefaults()
                }
                .disabled(voiceName.isEmpty)
            }
            List {
                ForEach(voices, id: \.self) { voice in
                    HStack {
                        Text(voice)
                        Spacer()
                        Button("Delete") {
                            voices = voices.filter({ value in
                                value != voice
                            })
                            saveVoicesToGroupDefaults()
                        }
                    }
                }
            }
        }
        .onAppear {
            voices = (groupDefaults?.value(forKey: "voices") as? [String]) ?? []
        }
        .padding()

    }
    
    // MARK: - Private Methods
    
    private func saveVoicesToGroupDefaults() {
        
        // Update the list of voices in the shared group defaults.
        groupDefaults?.set(voices, forKey: "voices")
        
        // Inform the system that the available voices changed.
        AVSpeechSynthesisProviderVoice.updateSpeechVoices()
        
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
