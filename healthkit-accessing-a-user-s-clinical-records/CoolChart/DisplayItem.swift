/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that holds the content for displayed items.
*/

struct DisplayItem {
    enum Accessory {
        case none
        case disclosure
    }
    
    let title: String
    let subtitle: String?
    let accessory: Accessory
    
    /// Because the app uses display items to populate a UITableViewCell, initialize the title, subtitle, and accessory.
    init(title: String, subtitle: String? = nil, accessory: Accessory = .none) {
        self.title = title
        self.subtitle = subtitle
        self.accessory = accessory
    }
    
    static let errorItem = DisplayItem(title: "Unknown", subtitle: "An error occurred")
}
