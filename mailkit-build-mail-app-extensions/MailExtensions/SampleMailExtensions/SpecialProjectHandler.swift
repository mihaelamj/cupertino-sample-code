/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The handler for special project selection.
*/

import Foundation
import MailKit

class SpecialProjectHandler {
    
    enum SpecialProject: String, CaseIterable {
        case marsRemoteOffice = "Mars Remote Office"
        case apSpaceShuttle = "AP Space Shuttle"
    }
    
    static let sharedHandler = SpecialProjectHandler()
    
    static let specialProjectsHeader = "x-special-projects"
    static let bannedDomain = "example.com"
    static let verifiedEmails: [MEEmailAddress] = [MEEmailAddress(rawString: "seth@example.com")]
    var selectedSpecialProject: SpecialProject? = nil
}
