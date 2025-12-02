/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
ClassKit support for the play library.
*/

import Foundation
import ClassKit
import os

/// ClassKit extensions to the play library for building contexts.
extension PlayLibrary: CLSDataStoreDelegate {
    /// Prepares this class to handle ClassKit context creation.
    /// - Tag: setupClassKit
    func setupClassKit() {
        CLSDataStore.shared.delegate = self
    }
    
    /// Traverses all the known contexts to prompt their creation, if needed.
    ///
    /// - Parameter play: The play whose contexts should be built.
    ///
    /// For students, this may quietly fail because they can't
    /// create a context until a teacher assigns the corresponding material.
    /// But because we don't know if the user is teacher or student, it's
    /// always best to try this once when building a new play.
    ///
    /// - Tag: setupContext
    func setupContext(play: Play) {
        for act in play.acts {
            for scene in act.scenes {
                
                // Get the deepest path: the quiz if there is one, or the scene if not.
                let path = scene.quiz?.identifierPath ?? scene.identifierPath
                
                // Asking for a context causes it (and its ancestors) to be built, as needed.
                CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: path) { _, _ in }
            }
        }
    }

    /// Creates the context specified by the identifier for the given parent.
    ///
    /// - Tag: createContext
    func createContext(forIdentifier identifier: String, parentContext: CLSContext, parentIdentifierPath: [String]) -> CLSContext? {
        
        // Find a node in the model hierarchy based on the identifier path.
        let identifierPath = parentIdentifierPath + [identifier]
    
        guard let playIdentifier = identifierPath.first,
            let play = PlayLibrary.shared.plays.first(where: { $0.identifier == playIdentifier }),
            let node = play.descendant(matching: Array(identifierPath.suffix(identifierPath.count - 1))) else {
            return nil
        }
        
        // Use the node to create and customize a context.
        let context = CLSContext(type: node.contextType, identifier: identifier, title: node.identifier)
        context.topic = .literacyAndWriting

        // Users of 11.3 rely on a user activity instead.
        if #available(iOS 11.4, *),
            let path = identifierPath.joined(separator: "/").addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) {

            // Use custom URLs to locate activities.
            //  Comment this assignment to rely on a user activity for all users.
            context.universalLinkURL = URL(string: "greatplays://" + path)
        }

        // No need to save: the framework handles that automatically.
        os_log("%s Built", node.identifierPath.description)
        return context
    }
}
