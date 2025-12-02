/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The ClassKit context provider.
*/

import ClassKit
import os

class ContextRequestHandler: NSObject, NSExtensionRequestHandling, CLSContextProvider {
    
    func beginRequest(with context: NSExtensionContext) {
        os_log("Begin request")
    }
    
    func updateDescendants(of context: CLSContext, completion: @escaping (Error?) -> Void) {
        
        // Replicate the data from the main app, but set creatingContexts to false to
        //  skip building the play's entire context tree. Instead, use the rest of the
        //  current method to build only the direct descendants of the passed-in context.
        PlayLibrary.shared.addPlay(PlayLibrary.hamlet, creatingContexts: false)
        
        // Get the parent context's identifier path, omitting the main app context.
        let identifierPath = Array(context.identifierPath.dropFirst())
        os_log("Build children of %s", identifierPath.description)

        // Start with plays as child nodes. Then look for a descendant.
        var childNodes: [Node] = PlayLibrary.shared.plays
        
        if let identifier = identifierPath.first,
            let play = PlayLibrary.shared.plays.first(where: { $0.identifier == identifier }),
            let node = play.descendant(matching: Array(identifierPath.suffix(identifierPath.count - 1))) {

            childNodes = node.children ?? []
        }

        // Get existing children of the given context. Then create missing ones
        // reusing the delegate call already implemented in the play library for this purpose.
        let predicate = NSPredicate(format: "%K = %@",
                                    CLSPredicateKeyPath.parent as CVarArg,
                                    context)
        CLSDataStore.shared.contexts(matching: predicate) { childContexts, _ in
            for childNode in childNodes {
                if !childContexts.contains(where: { $0.identifier == childNode.identifier }),
                    let childContext = PlayLibrary.shared.createContext(forIdentifier: childNode.identifier,
                                                                        parentContext: context,
                                                                        parentIdentifierPath: identifierPath) {
                    context.addChildContext(childContext)
                }
            }

            CLSDataStore.shared.save { error in
                if let error = error {
                    os_log("Save error: %s", error.localizedDescription)
                } else {
                    os_log("Saved")
                }
                completion(error)
            }
        }
    }
}

// An extension to provide a complete identifier path for a given ClassKit context.
extension CLSContext {
    var identifierPath: [String] {
        var pathComponents: [String] = [identifier]
        
        if let parent = self.parent {
            pathComponents = parent.identifierPath + pathComponents
        }
        
        return pathComponents
    }
}
