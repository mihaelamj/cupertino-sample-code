/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An actor that generates speech from text.
*/

import AVFAudio

actor SpeechSynthesizer {
    
    private let speechSynth = AVSpeechSynthesizer()
    
    func synthesizeSpeech(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        // Use an enhanced-quality voice if one exists for the current language code.
        utterance.voice = AVSpeechSynthesisVoice.speechVoices().first {
            $0.language == AVSpeechSynthesisVoice.currentLanguageCode() && $0.quality == .enhanced
        }
        // Speak the passed in text.
        speechSynth.speak(utterance)
    }
    
    func stop() {
        speechSynth.stopSpeaking(at: .word)
    }
}
