/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A document that manages access to a particle system.
*/

import UIKit
import SceneKit

// The Document class subclasses `UIDocument` so that it inherits all of the `UIDocument` class's features, such as coordinated reads and writes.
class Document: UIDocument {
    
    var particleSystem: SCNParticleSystem?
    var error: Error?
    
    override func contents(forType typeName: String) throws -> Any {
        guard let particleSystem = particleSystem else { return Data() }
        
        // This method is invoked whenever a document needs to be saved.
        // Particles documents are basically blobs of encoded particle systems.
        
        return try NSKeyedArchiver.archivedData(withRootObject: particleSystem, requiringSecureCoding: true)
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        
        // This method is invoked when loading a document from previously saved data.
        // Therefore, unarchive the stored data and use it as the particle system.
        
        guard let data = contents as? Data else {
            particleSystem = SCNParticleSystem()
            return
        }
        
        let system = try NSKeyedUnarchiver.unarchivedObject(ofClass: SCNParticleSystem.self, from: data)

        particleSystem = system
    }
    
    override func handleError(_ error: Error, userInteractionPermitted: Bool) {
        // Save the error in case we need to pass it on (thumbnail extension)
        self.error = error
        
        // Call super to handle the error
        super.handleError(error, userInteractionPermitted: userInteractionPermitted)
    }
}
