/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view of the iOS app.
*/

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        List {
            Section(header: Text("Request Authorization").font(.title2)) {
                Button {
                    requestUserNotificationsAuthorization()
                } label: {
                    row(icon: .authorization, title: "UserNotifications")
                }
                Button {
                    requestFocusStatusAuthorization()
                } label: {
                    row(icon: .authorization, title: "FocusStatus")
                }
            }
            Section(header: Text("Focus Status").font(.title2)) {
                Button {
                    requestFocusStatus()
                } label: {
                    row(icon: .authorization, title: "Request Focus Status")
                }
            }
            Section(header: Text("Suggest Outgoing Communication").font(.title2)) {
                Button {
                    suggestOutgoingOneOnOneMessage()
                } label: {
                    row(icon: .message, title: "One-on-one Message")
                }
                Button {
                    suggestOutgoingGroupMessage(groupName: nil)
                } label: {
                    row(icon: .message, title: "Group Message\nDefault Group Name")
                }
                Button {
                    suggestOutgoingGroupMessage(groupName: "Family")
                } label: {
                    row(icon: .message, title: "Group Message\nGroup Name: Family")
                }
                Button {
                    suggestOutgoingOneOnOneCall()
                } label: {
                    row(icon: .call, title: "One-on-one Call")
                }
                Button {
                    suggestOutgoingGroupCall()
                } label: {
                    row(icon: .call, title: "Group Call")
                }
            }
            Section(header: Text("Suggest Incoming Communication").font(.title2)) {
                row(icon: .doc, title: "See NotificationService.swift")
            }
            
        }
    }

    private enum Icon {
        case message
        case call
        case authorization
        case doc
        
        var systemImageName: String {
            switch self {
                case .message: return "message.circle"
                case .call: return "phone.circle"
                case .authorization: return "triangle.circle"
                case .doc: return "doc.circle"
            }
        }
    }
    
    private func row(icon: Icon, title: String) -> some View {
        HStack {
            Image(systemName: icon.systemImageName)
                .font(.title3)
            Divider()
            Text(title)
                .font(.body)
        }
    }
}

// MARK: - Authorization
extension ContentView {
    func requestUserNotificationsAuthorization() {
        CommunicationInteractor.requestUserNotificationsAuthorization { result in
            switch result {
                case .success(let authorizationStatus):
                    print("Succeeded requesting user notifications authorization \(String(describing: authorizationStatus))")
                case .failure(let error):
                    print("Failed requesting user notifications authorization \(String(describing: error))")
            }
        }
    }
    
    func requestFocusStatusAuthorization() {
        if #available(iOS 15.0, watchOS 8.0, macOS 12.0, *) {
            CommunicationInteractor.requestFocusStatusAuthorization { result in
                switch result {
                    case .success(let authorizationStatus):
                        print("Succeeded requesting focus status authorization \(String(describing: authorizationStatus))")
                    case .failure(let error):
                        print("Failed requesting focus status authorization \(String(describing: error))")
                }
            }
        } else {
            print("Focus Status Unavailable")
        }
    }
}

// MARK: - FocusStatus
extension ContentView {
    func requestFocusStatus() {
        if #available(iOS 15.0, watchOS 8.0, macOS 12.0, *) {
            CommunicationInteractor.requestFocusStatus { result in
                switch result {
                    case .success(let isFocused):
                        print("Is focused: \(String(describing: isFocused))")
                    case .failure(let error):
                        print("Failed requesting focus status \(String(describing: error))")
                }
            }
        } else {
            print("Focus Status Unavailable")
        }
    }
}

// MARK: - Suggest Outgoing Communication
extension ContentView {
    func suggestOutgoingOneOnOneMessage() {
        // Prepare people involved.
        let sender = PersonInformation.currentUserSocialProfile()
        
        let recipientImage = AvatarImage.imageName("imageA")
        let recipientName = PersonName.nameComponents(givenName: "Karina",
                                                      familyName: "Cavanna")
        let recipient = PersonInformation(name: recipientName,
                                          userIdentifier: .socialProfile("@karinaCavanna"),
                                          contactIdentifier: nil,
                                          avatarImage: recipientImage,
                                          isCurrentUser: false)
        
        let conversationIdentifier = "Karina-Conversation-Id"
        let oneOnOneInformation = PeopleInvolved.OneOnOneInformation(sender: sender, recipient: recipient)
        let peopleInvolved = PeopleInvolved.oneOnOne(oneOnOneInformation)
        
        // Prepare communication information.
        let communicationInformation = CommunicationType
            .outgoingMessage
            .peopleInvolved(peopleInvolved,
                            conversationIdentifier: conversationIdentifier)
        
        // Suggest communication information.
        self.suggest(communicationInformation: communicationInformation)
    }
    
    func suggestOutgoingGroupMessage(groupName: String?) {
        // Prepare people involved.
        let sender = PersonInformation.currentUserSocialProfile()
        
        let recipient1Image = AvatarImage.imageName("imageA")
        let recipient1Name = PersonName.nameComponents(givenName: "Karina",
                                                       familyName: "Cavanna")
        let recipient1 = PersonInformation(name: recipient1Name,
                                           userIdentifier: .socialProfile("@karinaCavanna"),
                                           contactIdentifier: nil,
                                           avatarImage: recipient1Image,
                                           isCurrentUser: false)
        
        let recipient2Image = AvatarImage.systemImageNamed("person.crop.circle")
        let recipient2 = PersonInformation(name: .displayName("Michael Cavanna"),
                                           userIdentifier: .phoneNumber("1-202-555-0156"),
                                           contactIdentifier: nil,
                                           avatarImage: recipient2Image,
                                           isCurrentUser: false)
        let relevantRecipients = [recipient1, recipient2]
        
        var groupAvatarImage: AvatarImage?
        if let exampleImageData = exampleImageData(imageName: "imageB") {
            groupAvatarImage = AvatarImage.imageData(exampleImageData)
        }
        let conversationIdentifier = "Bailey-Karina-Michael-Conversation-ID"
        let groupInformation = PeopleInvolved.GroupInformation(sender: sender,
                                                               relevantRecipients: relevantRecipients,
                                                               recipientCount: 12,
                                                               groupName: groupName,
                                                               groupAvatarImage: groupAvatarImage)
        let peopleInvolved = PeopleInvolved.group(groupInformation)
        
        // Prepare communication information.
        let communicationInformation = CommunicationType
            .outgoingMessage
            .peopleInvolved(peopleInvolved,
                            conversationIdentifier: conversationIdentifier)
        
        // Suggest communication information.
        self.suggest(communicationInformation: communicationInformation)
    }
    
    func suggestOutgoingOneOnOneCall() {
        // Prepare people involved.
        let sender = PersonInformation.currentUserSocialProfile()
        
        let recipientImage = AvatarImage.systemImageNamed("person.crop.circle")
        let recipient = PersonInformation(name: .displayName("Michael Cavanna"),
                                          userIdentifier: .phoneNumber("1-202-555-0156"),
                                          contactIdentifier: nil,
                                          avatarImage: recipientImage,
                                          isCurrentUser: false)
        
        let conversationIdentifer = "Michael-Conversation-Id"
        let oneOnOneInformation = PeopleInvolved.OneOnOneInformation(sender: sender, recipient: recipient)
        let peopleInvolved = PeopleInvolved.oneOnOne(oneOnOneInformation)
        
        // Prepare communication information.
        let communicationInformation = CommunicationType
            .outgoingCall
            .peopleInvolved(peopleInvolved,
                            conversationIdentifier: conversationIdentifer)
        
        // Suggest communication information.
        self.suggest(communicationInformation: communicationInformation)
    }
    
    func suggestOutgoingGroupCall() {
        // Prepare people involved.
        let sender = PersonInformation.currentUserSocialProfile()
        
        let  groupAvatarImage = AvatarImage.imageName("imageB")
        
        let recipient1Image = AvatarImage.systemImageNamed("person.crop.circle")
        let recipient1 = PersonInformation(name: .displayName("Michael Cavanna"),
                                           userIdentifier: .phoneNumber("1-202-555-0156"),
                                           contactIdentifier: nil,
                                           avatarImage: recipient1Image,
                                           isCurrentUser: false)
        let recipient2 = PersonInformation(name: .displayName("Marisa Cavanna"),
                                           userIdentifier: .phoneNumber("1-202-555-0148"),
                                           contactIdentifier: nil,
                                           avatarImage: nil,
                                           isCurrentUser: false)
        let relevantRecipients = [recipient1, recipient2]
        let conversationIdentifer = "Michael-Conversation-Id"
        let groupInformation = PeopleInvolved.GroupInformation(sender: sender,
                                                               relevantRecipients: relevantRecipients,
                                                               recipientCount: 5,
                                                               groupName: nil,
                                                               groupAvatarImage: groupAvatarImage,
                                                               isReplyToCurrentUser: false,
                                                               mentionsCurrentUser: false)
        let peopleInvolved = PeopleInvolved.group(groupInformation)
        // Prepare communication information.
        let communicationInformation = CommunicationType
            .outgoingCall
            .peopleInvolved(peopleInvolved,
                            conversationIdentifier: conversationIdentifer)
        
        // Suggest communication information.
        self.suggest(communicationInformation: communicationInformation)
    }
    
    private func suggest(communicationInformation: CommunicationInformation) {
        CommunicationInteractor
            .suggest(communicationInformation: communicationInformation) { result in
                switch result {
                    case .failure(let error):
                        print("Failed to suggest information with error:\n\(String(describing: error))")
                    case .success:
                        print("Suggested successfully:\n\(communicationInformation)")
                }
            }
    }
    
    /// Optional: Cache avatar image to be used by incoming communication notifications.
    private func cacheSuggestedImage(_ avatarImage: AvatarImage,
                                     avatarIdentifier: String) {
        AvatarRepository
            .shared
            .updateImageStore(avatarIdentifier: avatarIdentifier,
                              avatarImage: avatarImage)
    }
    
    /// Generates an image data object from a UIImage in bundle.
    private func exampleImageData(imageName: String) -> Data? {
        let uiImage = UIImage(named: imageName)
        return uiImage?.jpegData(compressionQuality: 0.9)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
