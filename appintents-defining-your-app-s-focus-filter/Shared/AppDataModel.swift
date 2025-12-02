/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data model to use for sharing information between the app and its App Intents extension.
*/

import Foundation

struct AppDataModel: Codable {
    init(alwaysUseDarkMode: Bool = false,
         status: String? = nil,
         selectedAccountID: String? = nil) {
        self.alwaysUseDarkMode = alwaysUseDarkMode
        self.status = status
        self.selectedAccountID = selectedAccountID
    }
    
    let alwaysUseDarkMode: Bool
    let status: String?
    let selectedAccountID: String?
    
    var isFocusFilterEnabled: Bool {
        alwaysUseDarkMode == true || status != nil || selectedAccountID != nil
    }
}
