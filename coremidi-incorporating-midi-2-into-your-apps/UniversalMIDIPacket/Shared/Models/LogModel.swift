/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model representing an onscreen log.
*/

import Foundation

class LogModel: ObservableObject {
    
    @Published var logData: String
    
    init(logData: String = .init()) {
        self.logData = logData
    }
    
    func print(_ text: String, printToTerm: Bool = false) {
        logData += text + "\n"
        if printToTerm {
            Swift.print(text)
        }
    }
    
    func clear() {
        logData.removeAll()
    }
    
}
