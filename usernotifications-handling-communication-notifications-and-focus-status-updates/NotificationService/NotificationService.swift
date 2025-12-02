/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The notification service extension class in charge of updating incoming push notifications with communication information.
*/

import UserNotifications
import os.log

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            if #available(iOSApplicationExtension 15.0, watchOSApplicationExtension 8.0, macOSApplicationExtension 12.0, *) {
                // Provide a way to let the app know this is a communication notification.
                let conversationIdentifier = bestAttemptContent.userInfo["conversationIdentifier"]
                guard let conversationIdentifier = conversationIdentifier as? String,
                      let communicationInformation = communicationInformation(conversationIdentifier) else {
                          contentHandler(bestAttemptContent)
                          return
                      }
                
                // Update notification content with communication information.
                CommunicationInteractor
                    .update(notificationContent: bestAttemptContent,
                            communicationInformation: communicationInformation) { [weak self, contentHandler, bestAttemptContent] result in
                        switch result {
                            case .failure(let error):
                                self?.logger.error("Failed to update incoming notification \(String(describing: error))")
                                contentHandler(bestAttemptContent)
                            case .success(let updatedContent):
                                contentHandler(updatedContent)
                        }
                    }
            } else {
                contentHandler(bestAttemptContent)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your best attempt at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private var logger = Logger(subsystem: "Sample App",
                                category: String(describing: NotificationService.self))
}

// MARK: Suggestion Examples
extension NotificationService {
    private func communicationInformation(_ conversationIdentifier: String) -> CommunicationInformation? {
        // Retrieve conversation information from local or remote store.
        
        // Examples:
        var avatarImage: AvatarImage?
        if let imageData = try? AvatarRepository.shared.imageData(identifier: conversationIdentifier) {
            avatarImage = .imageData(imageData)
        } else if let imageName = try? AvatarRepository.shared.imageName(identifier: conversationIdentifier) {
            avatarImage = .imageName(imageName)
        } else {
            // Download image from remote store and cache.
            // avatarImage = .imageData(downloadedImageData)
            
            // Using system image:
            // avatarImage = .systemImageNamed("person.crop.circle")
            
            // Using image in bundle:
            avatarImage = .imageName("imageA")
        }
        
        // One-on-one message.
        let oneOnOne = oneOnOneMessageExample(conversationIdentifier,
                                              notifyRecipientAnyway: false,
                                              senderAvatarImage: avatarImage)
        
        // Other communication type examples:
        
        // One-on-one message. Sender was notified the recipient is focused and requested to notify them anyway.
        _ = oneOnOneMessageExample(conversationIdentifier,
                                   notifyRecipientAnyway: true,
                                   senderAvatarImage: avatarImage)
        // Group message with default name (Subtitle: To you & <Other Recipients>).
        _ = groupMessageExample(conversationIdentifier,
                                notifyRecipientAnyway: false,
                                groupName: nil,
                                groupAvatarImage: avatarImage)
        // Group message with custom name in subtitle.
        _ = groupMessageExample(conversationIdentifier,
                                notifyRecipientAnyway: false,
                                groupName: "Family",
                                groupAvatarImage: avatarImage)
        
        // One-on-one voicemail.
        _ = voicemailExample(conversationIdentifier,
                             callerAvatarImage: avatarImage)
        
        // One-on-one missed call.
        _ = oneOnOneMissedCallExample(conversationIdentifier,
                                      callerAvatarImage: avatarImage)
        return oneOnOne
    }
    
    private func oneOnOneMessageExample(_ conversationIdentifier: String,
                                        notifyRecipientAnyway: Bool,
                                        senderAvatarImage: AvatarImage?) -> CommunicationInformation {
        // Prepare people involved.
        let senderName = PersonName.nameComponents(givenName: "Karina",
                                                   familyName: "Cavanna")
        let sender = PersonInformation(name: senderName,
                                       userIdentifier: .socialProfile("@karinaCavanna"),
                                       contactIdentifier: nil,
                                       avatarImage: senderAvatarImage,
                                       isCurrentUser: false)
        let recipient = PersonInformation.currentUserSocialProfile()
        let oneOnOneInformation = PeopleInvolved.OneOnOneInformation(sender: sender, recipient: recipient)
        let peopleInvolved = PeopleInvolved.oneOnOne(oneOnOneInformation)
        
        // Prepare communication information.
        return CommunicationType
            .incomingMessage(notifyRecipientAnyway: notifyRecipientAnyway)
            .peopleInvolved(peopleInvolved,
                            conversationIdentifier: conversationIdentifier)
    }
    
    private func groupMessageExample(_ conversationIdentifier: String,
                                     notifyRecipientAnyway: Bool,
                                     groupName: String?,
                                     groupAvatarImage: AvatarImage?) -> CommunicationInformation {
        // Prepare people involved.
        let senderName = PersonName.nameComponents(givenName: "Karina",
                                                   familyName: "Cavanna")
        let sender = PersonInformation(name: senderName,
                                       userIdentifier: .socialProfile("@karinaCavanna"),
                                       contactIdentifier: nil,
                                       avatarImage: nil,
                                       isCurrentUser: false)
        let recipient1 = PersonInformation.currentUserSocialProfile()
        let recipient2 = PersonInformation(name: .displayName("Michael Cavanna"),
                                           userIdentifier: .phoneNumber("1-202-555-0156"),
                                           contactIdentifier: nil,
                                           avatarImage: nil,
                                           isCurrentUser: false)
        let relevantRecipients = [recipient1, recipient2]
        let groupInformation = PeopleInvolved.GroupInformation(sender: sender,
                                                               relevantRecipients: relevantRecipients,
                                                               recipientCount: 12,
                                                               groupName: groupName,
                                                               groupAvatarImage: groupAvatarImage)
        let peopleInvolved = PeopleInvolved.group(groupInformation)
        
        // Prepare communication information.
        return CommunicationType
            .incomingMessage(notifyRecipientAnyway: notifyRecipientAnyway)
            .peopleInvolved(peopleInvolved,
                            conversationIdentifier: conversationIdentifier)
    }
    
    private func voicemailExample(_ conversationIdentifier: String,
                                  callerAvatarImage: AvatarImage?) -> CommunicationInformation {
        // Prepare people involved.
        let caller = PersonInformation(name: .displayName("Michael Cavanna"),
                                       userIdentifier: .phoneNumber("1-202-555-0156"),
                                       contactIdentifier: nil,
                                       avatarImage: callerAvatarImage,
                                       isCurrentUser: false)
        let recipient = PersonInformation.currentUserSocialProfile()
        let oneOnOneInformation = PeopleInvolved.OneOnOneInformation(sender: caller, recipient: recipient)
        let peopleInvolved = PeopleInvolved.oneOnOne(oneOnOneInformation)
        
        // Prepare communication information.
        return CommunicationType
            .incomingVoicemail
            .peopleInvolved(peopleInvolved,
                            conversationIdentifier: conversationIdentifier)
    }
    
    private func oneOnOneMissedCallExample(_ conversationIdentifier: String,
                                           callerAvatarImage: AvatarImage?) -> CommunicationInformation {
        // Prepare people involved.
        let caller = PersonInformation(name: .displayName("Michael Cavanna"),
                                       userIdentifier: .phoneNumber("1-202-555-0156"),
                                       contactIdentifier: nil,
                                       avatarImage: callerAvatarImage,
                                       isCurrentUser: false)
        let recipient = PersonInformation.currentUserSocialProfile()
        let oneOnOneInformation = PeopleInvolved.OneOnOneInformation(sender: caller, recipient: recipient)
        let peopleInvolved = PeopleInvolved.oneOnOne(oneOnOneInformation)
        
        // Prepare communication information.
        return CommunicationType
            .incomingMissedCall
            .peopleInvolved(peopleInvolved,
                            conversationIdentifier: conversationIdentifier)
    }
}
