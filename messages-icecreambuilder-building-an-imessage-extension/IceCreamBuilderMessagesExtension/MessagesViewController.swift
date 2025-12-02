/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The root view controller shown by the Messages app.
*/

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {

    // MARK: Properties
    
    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        
        // Present the view controller appropriate for the conversation and presentation style.
        presentViewController(for: conversation, with: presentationStyle)
    }
    
    // MARK: MSMessagesAppViewController overrides
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.willTransition(to: presentationStyle)
        
        // Hide child view controllers during the transition.
        removeAllChildViewControllers()
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        
        // Present the view controller appropriate for the conversation and presentation style.
        guard let conversation = activeConversation else { fatalError("Expected an active converstation") }
        presentViewController(for: conversation, with: presentationStyle)
    }
    
    // MARK: Child view controller presentation
    
    /// - Tag: PresentViewController
    private func presentViewController(for conversation: MSConversation, with presentationStyle: MSMessagesAppPresentationStyle) {
        // Remove any child view controllers that have been presented.
        removeAllChildViewControllers()
        
        let controller: UIViewController
        if presentationStyle == .compact {
            // Show a list of previously created ice creams.
            controller = instantiateIceCreamsController()
        } else {
             // Parse an `IceCream` from the conversation's `selectedMessage` or create a new `IceCream`.
            let iceCream = IceCream(message: conversation.selectedMessage) ?? IceCream()

            // Show either the in process construction process or the completed ice cream.
            if iceCream.isComplete {
                controller = instantiateCompletedIceCreamController(with: iceCream)
            } else {
                controller = instantiateBuildIceCreamController(with: iceCream)
            }
        }

        addChild(controller)
        controller.view.frame = view.bounds
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        
        NSLayoutConstraint.activate([
            controller.view.leftAnchor.constraint(equalTo: view.leftAnchor),
            controller.view.rightAnchor.constraint(equalTo: view.rightAnchor),
            controller.view.topAnchor.constraint(equalTo: view.topAnchor),
            controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        
        controller.didMove(toParent: self)
    }
    
    private func instantiateIceCreamsController() -> UIViewController {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: IceCreamsViewController.storyboardIdentifier)
            as? IceCreamsViewController
            else { fatalError("Unable to instantiate an IceCreamsViewController from the storyboard") }
        
        controller.delegate = self
        
        return controller
    }
    
    private func instantiateBuildIceCreamController(with iceCream: IceCream) -> UIViewController {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: BuildIceCreamViewController.storyboardIdentifier)
            as? BuildIceCreamViewController
            else { fatalError("Unable to instantiate a BuildIceCreamViewController from the storyboard") }
        
        controller.iceCream = iceCream
        controller.delegate = self
        
        return controller
    }
    
    private func instantiateCompletedIceCreamController(with iceCream: IceCream) -> UIViewController {
        // Instantiate a `BuildIceCreamViewController`.
        guard let controller = storyboard?.instantiateViewController(withIdentifier: CompletedIceCreamViewController.storyboardIdentifier)
            as? CompletedIceCreamViewController
            else { fatalError("Unable to instantiate a CompletedIceCreamViewController from the storyboard") }
        
        controller.iceCream = iceCream
        
        return controller
    }
    
    // MARK: Convenience
    
    private func removeAllChildViewControllers() {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
    }
    
    /// - Tag: ComposeMessage
    fileprivate func composeMessage(with iceCream: IceCream, caption: String, session: MSSession? = nil) -> MSMessage {
        var components = URLComponents()
        components.queryItems = iceCream.queryItems
        
        let layout = MSMessageTemplateLayout()
        layout.image = iceCream.renderSticker(opaque: true)
        layout.caption = caption
        
        let message = MSMessage(session: session ?? MSSession())
        message.url = components.url!
        message.layout = layout
        
        return message
    }
}

/// Extends `MessagesViewController` to conform to the `IceCreamsViewControllerDelegate` protocol.

extension MessagesViewController: IceCreamsViewControllerDelegate {

    func iceCreamsViewControllerDidSelectAdd(_ controller: IceCreamsViewController) {
        requestPresentationStyle(.expanded)
    }
}

/// Extends `MessagesViewController` to conform to the `BuildIceCreamViewControllerDelegate` protocol.

extension MessagesViewController: BuildIceCreamViewControllerDelegate {

    /// - Tag: InsertMessageInConversation
    func buildIceCreamViewController(_ controller: BuildIceCreamViewController, didSelect iceCreamPart: IceCreamPart) {
        guard let conversation = activeConversation else { fatalError("Expected a conversation") }
        guard var iceCream = controller.iceCream else { fatalError("Expected the controller to be displaying an ice cream") }

        // Update the ice cream with the selected body part and determine a caption and description of the change.
        var messageCaption: String
        if let base = iceCreamPart as? Base {
            iceCream.base = base
            messageCaption = NSLocalizedString("Let's build an ice cream", comment: "")
        } else if let scoops = iceCreamPart as? Scoops {
            iceCream.scoops = scoops
            messageCaption = NSLocalizedString("I added some scoops", comment: "")
        } else if let topping = iceCreamPart as? Topping {
            iceCream.topping = topping
            messageCaption = NSLocalizedString("Our finished ice cream", comment: "")
        } else {
            fatalError("Unexpected type of ice cream part selected.")
        }

        // Create a new message with the same session as any currently selected message.
        let message = composeMessage(with: iceCream, caption: messageCaption, session: conversation.selectedMessage?.session)

        // Add the message to the conversation.
        conversation.insert(message) { error in
            if let error = error {
                print(error)
            }
        }

        // If the ice cream is complete, save it in the history.
        if iceCream.isComplete {
            var history = IceCreamHistory.load()
            history.append(iceCream)
            history.save()
        }
        
        dismiss()
    }
}
