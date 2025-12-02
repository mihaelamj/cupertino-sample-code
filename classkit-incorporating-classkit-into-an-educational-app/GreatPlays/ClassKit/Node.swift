/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A node in the data model hierarchy.
*/

import ClassKit
import os

/// A node in the data model hierarchy.
/// - Tag: nodeProtocolDeclaration
protocol Node {
    var parent: Node? { get }
    var children: [Node]? { get }
    var identifier: String { get }
    var contextType: CLSContextType { get }
}

// MARK: Identifiers

extension Node {
    var identifierPath: [String] {
        var pathComponents: [String] = [identifier]
        
        if let parent = self.parent {
            pathComponents = parent.identifierPath + pathComponents
        }
        
        return pathComponents
    }
    
    /// Finds a node in the play list hierarchy by its identifier path.
    func descendant(matching identifierPath: [String]) -> Node? {
        if let identifier = identifierPath.first {
            if let child = children?.first(where: { $0.identifier == identifier }) {
                return child.descendant(matching: Array(identifierPath.suffix(identifierPath.count - 1)))
            } else {
                return nil
            }
        } else {
            return self
        }
    }
}

// MARK: Activity

extension Node {
    /// Activates the context for this node and starts its activity.
    /// - Tag: startActivity
    func startActivity(asNew: Bool = false) {
        os_log("%s Start", identifierPath.description)

        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: identifierPath) { context, _ in

            // Activate the context.
            context?.becomeActive()

            if asNew == false,
                let activity = context?.currentActivity {
                
                // Re-start the existing activity
                activity.start()
                
            } else {
                // Create and start an activity.
                context?.createNewActivity().start()
            }
            
            CLSDataStore.shared.save { error in
                guard error == nil else {
                    os_log("%s Start save error: %s", self.identifierPath.description, error!.localizedDescription)
                    return
                }
            }
        }
    }

    /// Updates the current activity with latest progress.
    /// - Tag: updateProgress
    func update(progress: Double) {
        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: identifierPath) { context, _ in
            guard let activity = context?.currentActivity,
                progress > activity.progress,
                activity.isStarted else { return }
            
            activity.addProgressRange(fromStart: 0, toEnd: progress)
            os_log("%s Progress: %d%%", self.identifierPath.description, Int(progress * 100))
        }
    }

    /// Adds a score as the primary activity item.
    /// - Tag: addScore
    func addScore(_ score: Double, title: String, primary: Bool = false) {
        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: identifierPath) { context, _ in
            guard let activity = context?.currentActivity,
                activity.isStarted else { return }

            // Create the score item and add it.
            let item = CLSScoreItem(identifier: "score", title: title, score: score, maxScore: 1)

            if primary {
                activity.primaryActivityItem = item
            } else {
                activity.addAdditionalActivityItem(item)
            }

            os_log("%s %s: %s", self.identifierPath.description, title, score.description)
        }
    }
    
    /// Adds a quantity as a secondary item.
    /// - Tag: addQuantity
    func addQuantity(_ quantity: Double, title: String, primary: Bool = false) {
        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: identifierPath) { context, _ in
            guard let activity = context?.currentActivity,
                activity.isStarted else { return }

            // Create the quantity item and add it.
            let item = CLSQuantityItem(identifier: "quantity", title: title)
            item.quantity = quantity
            
            if primary {
                activity.primaryActivityItem = item
            } else {
                activity.addAdditionalActivityItem(item)
            }
            
            os_log("%s %s: %s", self.identifierPath.description, title, quantity.description)
        }
    }
    
    /// Stops the current context and its activity.
    /// - Tag: stopActivity
    func stopActivity() {
        CLSDataStore.shared.mainAppContext.descendant(matchingIdentifierPath: identifierPath) { context, _ in
            guard let activity = context?.currentActivity else { return }

            os_log("%s Stop: %.1f seconds elapsed", self.identifierPath.description, activity.duration)

            activity.stop()
            context?.resignActive()
            
            CLSDataStore.shared.save { error in
                guard error == nil else {
                    os_log("%s End save error: %s", self.identifierPath.description, error!.localizedDescription)
                    return
                }
            }
        }
    }
    
    /// Marks all assigned activities in the context as done.
    /// - Tag: markAsDone
    func markAsDone() {
        if #available(iOS 12.2, *) {
            os_log("%s Done", identifierPath.description)
            CLSDataStore.shared.completeAllAssignedActivities(matching: identifierPath)
        }
    }
}
