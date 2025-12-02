/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
GoatNames provides an abstraction for generating names to create Goat objects.
*/

import Foundation

class GoatNames {
    
    private static let goatNames = ["Happy Goat", "Silly Goat", "Hungry Goat", "Billy Goat",
                                    "Sleepy Goat", "Smart Goat", "Mountain Goat", "Goatee"]
    
    private static var goatNameCounter = [String: Int]()
    static func generateGoatName() -> String {
        // Generates a random goat name based on the list of available names.
        guard let goatName = goatNames.randomElement() else {
            return "Default Goat"
        }
        
        let counter = goatNameCounter[goatName, default: 1]
        goatNameCounter[goatName] = counter + 1
        return goatName + " " + String(counter)
    }
    
}
