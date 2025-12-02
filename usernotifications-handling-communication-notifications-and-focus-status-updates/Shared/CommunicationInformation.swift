/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data model containing essential information to suggest a communication.
*/

import Foundation

enum CommunicationType {
    case outgoingMessage
    case incomingMessage(notifyRecipientAnyway: Bool = false)
    case outgoingCall
    case incomingVoicemail
    case incomingMissedCall
    
    func peopleInvolved(_ peopleInvolved: PeopleInvolved,
                        conversationIdentifier: String) -> CommunicationInformation {
        return CommunicationInformation(type: self,
                                        peopleInvolved: peopleInvolved,
                                        conversationIdentifier: conversationIdentifier)
    }
}

enum PeopleInvolved {
    case group(GroupInformation)
    case oneOnOne(OneOnOneInformation)
    
    struct GroupInformation {
        internal init(sender: PersonInformation,
                      relevantRecipients: [PersonInformation],
                      recipientCount: Int,
                      groupName: String? = nil,
                      groupAvatarImage: AvatarImage? = nil,
                      isReplyToCurrentUser: Bool = false,
                      mentionsCurrentUser: Bool = false) {
            self.sender = sender
            self.relevantRecipients = relevantRecipients
            self.recipientCount = recipientCount
            self.groupName = groupName
            self.groupAvatarImage = groupAvatarImage
            self.isReplyToCurrentUser = isReplyToCurrentUser
            self.mentionsCurrentUser = mentionsCurrentUser
        }

        let sender: PersonInformation
        let relevantRecipients: [PersonInformation]
        let recipientCount: Int
        let groupName: String?
        let groupAvatarImage: AvatarImage?
        let isReplyToCurrentUser: Bool
        let mentionsCurrentUser: Bool
    }
    
    struct OneOnOneInformation {
        let sender: PersonInformation
        let recipient: PersonInformation
    }
}

struct CommunicationInformation {
    let type: CommunicationType
    let peopleInvolved: PeopleInvolved
    let conversationIdentifier: String
}

