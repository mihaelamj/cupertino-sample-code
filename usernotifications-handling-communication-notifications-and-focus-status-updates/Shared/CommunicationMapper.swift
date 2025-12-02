/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class in charge of mapping Communication Information into Intent framework objects.
*/

import Foundation
import Intents

enum CommunicationMapperError: Error {
    case unexpectedCommunicationType
    case missingRequiredPeople
}

struct CommunicationMapper {
    static func interaction(communicationInformation: CommunicationInformation) throws -> INInteraction {
        let direction: INInteractionDirection
        let intent: INIntent
        switch communicationInformation.type {
            case .outgoingMessage:
                direction = .outgoing
                intent = try Self.message(communicationInformation: communicationInformation)
            case .incomingMessage:
                direction = .incoming
                intent = try Self.message(communicationInformation: communicationInformation)
            case .outgoingCall:
                direction = .outgoing
                intent = try Self.call(communicationInformation: communicationInformation)
            case .incomingVoicemail, .incomingMissedCall:
                direction = .incoming
                intent = try Self.call(communicationInformation: communicationInformation)
        }
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = direction
        return interaction
    }
    
    // MARK: - Message

    /// Maps a CommunicationInformation into a INSendMessageIntent.
    /// - Parameter communicationInformation: Communication Information.
    /// - Returns: INSendMessageIntent.
    static func message(communicationInformation: CommunicationInformation) throws -> INSendMessageIntent {
        let isIncoming: Bool = try isIncomingMessage(communicationInformation.type)
        // Get CommunicationType and check if recipient should be notified anyway.
        let notifyRecipientAnyway: Bool? = notifyRecipientAnyway(communicationInformation.type)
        // Get people involved.
        let groupInformation = try groupInformation(peopleInvolved: communicationInformation.peopleInvolved)
        let oneOnOneInformation = oneOnOneInformation(peopleInvolved: communicationInformation.peopleInvolved)
        let isGroup = groupInformation != nil
        // Setup group or one-on-one sender and receipients.
        var senderINPerson: INPerson?
        var recipientsINPersonArray: [INPerson]?
        if let groupInformation = groupInformation {
            senderINPerson = Self.person(personInformation: groupInformation.sender)
            recipientsINPersonArray = people(informationRecipients: groupInformation.relevantRecipients)
        } else if let oneOnOneInformation = oneOnOneInformation {
            senderINPerson = Self.person(personInformation: oneOnOneInformation.sender)
            recipientsINPersonArray = [Self.person(personInformation: oneOnOneInformation.recipient)]
        }
        // Group only.
        var speakableGroupName: INSpeakableString?
        if let groupName = groupInformation?.groupName {
            speakableGroupName = INSpeakableString(spokenPhrase: groupName)
        }
        let groupINImage: INImage? = Self.image(avatarImage: groupInformation?.groupAvatarImage)
        let overallRecipientCount: Int? = groupInformation?.recipientCount
        let metadataIsReplyToCurrentUser = groupInformation?.isReplyToCurrentUser
        let metadataMentionsCurrentUser = groupInformation?.mentionsCurrentUser
        // Prepare the intent.
        let intent = INSendMessageIntent(recipients: recipientsINPersonArray,
                                         outgoingMessageType: .outgoingMessageText,
                                         content: nil,
                                         speakableGroupName: speakableGroupName,
                                         conversationIdentifier: communicationInformation.conversationIdentifier,
                                         serviceName: nil,
                                         sender: senderINPerson,
                                         attachments: nil)
        // Set group avatar.
        if let groupINImage = groupINImage {
            intent.setImage(groupINImage, forParameterNamed: \.speakableGroupName)
        }
        // Set incoming message metadata.
        if isIncoming, #available(iOS 15.0, watchOS 8.0, macOS 12.0, *) {
            let prepareMetadata = prepareMetadata(notifyRecipientAnyway: notifyRecipientAnyway,
                                                  isGroup: isGroup,
                                                  overallRecipientCount: overallRecipientCount,
                                                  mentionsCurrentUser: metadataMentionsCurrentUser,
                                                  isReplyToCurrentUser: metadataIsReplyToCurrentUser)
            if prepareMetadata.needsUpdate {
                intent.donationMetadata = prepareMetadata.metaData
            }
        }
        return intent
    }
    
    // MARK: - Call
    static func call(communicationInformation: CommunicationInformation) throws -> INStartCallIntent {
        let destinationType = try destinationType(communicationInformation.type)
        let isIncoming: Bool = try isIncomingCall(communicationInformation.type)
        // Get people involved.
        let groupInformation = try groupInformation(peopleInvolved: communicationInformation.peopleInvolved)
        let oneOnOneInformation = oneOnOneInformation(peopleInvolved: communicationInformation.peopleInvolved)
        let isGroup = groupInformation != nil
        // Setup group or one-on-one contacts.
        var contacts: [INPerson]?
        if let groupInformation = groupInformation {
            contacts = try groupContacts(groupInformation)
        } else if let oneOnOneInformation = oneOnOneInformation {
            contacts = try oneOnOneContacts(oneOnOneInformation, isIncoming: isIncoming)
        }
        // Group only.
        let groupINImage: INImage? = Self.image(avatarImage: groupInformation?.groupAvatarImage)
        let overallContactsCount: Int? = groupInformation?.recipientCount
        // Prepare the intent.
        let intent = INStartCallIntent(callRecordFilter: nil,
                                       callRecordToCallBack: nil,
                                       audioRoute: .speakerphoneAudioRoute,
                                       destinationType: destinationType,
                                       contacts: contacts,
                                       callCapability: .audioCall)
        // Set group message avatar.
        if let groupINImage = groupINImage {
            intent.setImage(groupINImage, forParameterNamed: \.callRecordToCallBack)
        }
        // Set Incoming Message Metadata.
        if isIncoming, isGroup, #available(iOS 15.0, watchOS 8.0, macOS 12.0, *) {
            if let overallContactsCount = overallContactsCount {
                let metadata = INSendMessageIntentDonationMetadata()
                metadata.recipientCount = overallContactsCount
                intent.donationMetadata = metadata
            }
        }
        return intent
    }
}

// MARK: - Helper Functions
extension CommunicationMapper {
    
    /// Maps [PersonInformation] into [INPerson]?.
    /// - Parameter informationRecipients: [PersonInformation].
    /// - Returns: [INPerson] or nil if informationRecipients is empty.
    static private func people(informationRecipients: [PersonInformation],
                               includeCurrentUser: Bool = true) -> [INPerson]? {
        var recipients: [INPerson]?
        if !informationRecipients.isEmpty {
            recipients = [INPerson]()
            for personInformation in informationRecipients {
                if personInformation.isCurrentUser && includeCurrentUser == false {
                    continue
                }
                let recipient = Self.person(personInformation: personInformation)
                recipients?.append(recipient)
            }
        }
        return recipients
    }
       
    /// Maps a PersonInformation object into an INPerson.
    /// - Parameter personInformation: Person Information.
    /// - Returns: INPerson
    static private func person(personInformation: PersonInformation) -> INPerson {
        // Person Handle and Suggestion Type.
        let personHandle = personHandle(personInformation.userIdentifier)
        let suggestionType: INPersonSuggestionType = suggestionType(personInformation.userIdentifier)
        // Name.
        var displayName: String?
        var nameComponents: PersonNameComponents?
        
        switch personInformation.name {
            case .displayName(let personDisplayName):
                displayName = personDisplayName
            case .nameComponents(let givenName, let familyName):
                nameComponents = PersonNameComponents()
                nameComponents?.givenName = givenName
                nameComponents?.familyName = familyName
        }
        // Avatar Image.
        var image: INImage?
        if let avatarImage = personInformation.avatarImage {
            image = Self.image(avatarImage: avatarImage)
        }
        
        if #available(iOS 15.0, watchOS 8.0, macOS 12.0, *) {
            return INPerson(personHandle: personHandle,
                            nameComponents: nameComponents,
                            displayName: displayName,
                            image: image,
                            contactIdentifier: personInformation.contactIdentifier,
                            customIdentifier: personHandle.value,
                            isMe: personInformation.isCurrentUser,
                            suggestionType: suggestionType)
        } else {
            return INPerson(personHandle: personHandle,
                            nameComponents: nameComponents,
                            displayName: displayName,
                            image: image,
                            contactIdentifier: personInformation.contactIdentifier,
                            customIdentifier: personHandle.value,
                            isMe: personInformation.isCurrentUser)
        }
    }
    
    static private func personHandle(_ userIdentifier: UniqueUserIdentifier) -> INPersonHandle {
        switch userIdentifier {
            case .socialProfile(let socialProfile):
                return INPersonHandle(value: socialProfile,
                                      type: .unknown)
            case .phoneNumber(let phoneNumber):
                return INPersonHandle(value: phoneNumber,
                                      type: .phoneNumber)
            case .emailAddress(let emailAddress):
                return INPersonHandle(value: emailAddress,
                                      type: .emailAddress)
        }
    }
    
    static private func suggestionType(_ userIdentifier: UniqueUserIdentifier) -> INPersonSuggestionType {
        switch userIdentifier {
            case .socialProfile: return .socialProfile
            default: return .none
        }
    }
    
    /// Maps an AvatarImage into an INImage.
    /// - Parameter avatarImage: AvatarImage.
    /// - Returns: INImage.
    static private func image(avatarImage: AvatarImage?) -> INImage? {
        guard let avatarImage = avatarImage else {
            return nil
        }

        switch avatarImage {
            case .imageName(let imageName):
                return INImage(named: imageName)
            case .imageData(let data):
                return INImage(imageData: data)
            case .systemImageNamed(let systemImageName):
                return INImage.systemImageNamed(systemImageName)
        }
    }
    
    static private func isIncomingMessage(_ communicationType: CommunicationType) throws -> Bool {
        switch communicationType {
            case .outgoingMessage:
                return false
            case .incomingMessage:
                return true
            default:
                print("Unexpected CommunicationType in INSendMessageIntent mapper")
                throw CommunicationMapperError.unexpectedCommunicationType
        }
    }
    
    static private func notifyRecipientAnyway(_ communicationType: CommunicationType) -> Bool {
        if case let .incomingMessage(notifyAnyway) = communicationType {
            return notifyAnyway
        }
        return false
    }
    
    @available(iOS 15.0, *)
    static private func prepareMetadata(notifyRecipientAnyway: Bool?,
                                        isGroup: Bool,
                                        overallRecipientCount: Int?,
                                        mentionsCurrentUser: Bool?,
                                        isReplyToCurrentUser: Bool?) -> (needsUpdate: Bool, metaData: INSendMessageIntentDonationMetadata) {
        let metadata = INSendMessageIntentDonationMetadata()
        var needsUpdate = false
        
        // Notify Anyway.
        if let notifyRecipientAnyway = notifyRecipientAnyway {
            metadata.notifyRecipientAnyway = notifyRecipientAnyway
            needsUpdate = true
        }
        // Group Metadata.
        if isGroup {
            needsUpdate = true
            
            if let overallRecipientCount = overallRecipientCount {
                metadata.recipientCount = overallRecipientCount
            }
            
            if let mentionsCurrentUser = mentionsCurrentUser {
                metadata.mentionsCurrentUser = mentionsCurrentUser
            }
            if let isReplyToCurrentUser = isReplyToCurrentUser {
                metadata.isReplyToCurrentUser = isReplyToCurrentUser
            }
        }
        return (needsUpdate, metadata)
    }
    
    static func groupInformation(peopleInvolved: PeopleInvolved) throws -> PeopleInvolved.GroupInformation? {
        if case let .group(groupInformation) = peopleInvolved {
            if groupInformation.relevantRecipients.isEmpty {
                throw CommunicationMapperError.missingRequiredPeople
            }
            return groupInformation
        }
        return nil
    }
    
    static func oneOnOneInformation(peopleInvolved: PeopleInvolved) -> PeopleInvolved.OneOnOneInformation? {
        if case let .oneOnOne(oneOnOneInformation) = peopleInvolved {
            return oneOnOneInformation
        }
        return nil
    }
    
    static private func isIncomingCall(_ communicationType: CommunicationType) throws -> Bool {
        switch communicationType {
            case .outgoingCall:
                return false
            case .incomingVoicemail, .incomingMissedCall:
                return true
            default:
                print("Unexpected CommunicationType in INStartCallIntent mapper")
                throw CommunicationMapperError.unexpectedCommunicationType
        }
    }
    
    static private func destinationType(_ communicationType: CommunicationType) throws -> INCallDestinationType {
        switch communicationType {
            case .outgoingCall: return .normal
            case .incomingVoicemail: return .voicemail
            case .incomingMissedCall: return .callBack
            default:
                print("Unexpected CommunicationType in INStartCallIntent mapper")
                throw CommunicationMapperError.unexpectedCommunicationType
        }
    }
    
    static private func groupContacts(_ groupInformation: PeopleInvolved.GroupInformation) throws -> [INPerson] {
        var contactsInvolved = [INPerson]()
        if let recipients = people(informationRecipients: groupInformation.relevantRecipients,
                                   includeCurrentUser: false) {
            contactsInvolved.append(contentsOf: recipients)
        }
        if !groupInformation.sender.isCurrentUser {
            contactsInvolved.append(person(personInformation: groupInformation.sender))
        }
        if !contactsInvolved.isEmpty {
            return contactsInvolved
        } else {
            throw CommunicationMapperError.missingRequiredPeople
        }
    }
    
    static private func oneOnOneContacts(_ oneOnOneInformation: PeopleInvolved.OneOnOneInformation,
                                         isIncoming: Bool) throws -> [INPerson] {
        if isIncoming {
            if oneOnOneInformation.sender.isCurrentUser {
                throw CommunicationMapperError.missingRequiredPeople
            }
            return [person(personInformation: oneOnOneInformation.sender)]
        } else {
            if oneOnOneInformation.recipient.isCurrentUser {
                throw CommunicationMapperError.missingRequiredPeople
            }
            return [person(personInformation: oneOnOneInformation.recipient)]
        }
    }
}
