/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
GoatNames provides an abstraction for generating names to create Goat objects.
*/

import UIKit

struct Goat {
    var name: String

    init?(name: String) {
        // The name must not be empty
        guard !name.isEmpty else {
            return nil
        }
        
        // Initialize stored properties.
        self.name = name
    }
}
