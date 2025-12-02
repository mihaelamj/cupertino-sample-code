/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that represents a Home Screen bookmark.
*/

import SafariServices

class HomeScreenBookmarkItem: NSObject, SFAddToHomeScreenActivityItem {
  
  var url: URL
  var title: String
  var iconItemProvider: NSItemProvider?
  
  init(url: URL, title: String, iconItemProvider: NSItemProvider? = nil) {
    self.url = url
    self.title = title
    self.iconItemProvider = iconItemProvider
  }
}

extension HomeScreenBookmarkItem {
  
  convenience init(url: URL, title: String) {
    var iconItemProvider: NSItemProvider? = nil
    let imageName = "Bookmark"
    if let image = UIImage(named: imageName) {
      iconItemProvider = .init(object: image)
    }
    self.init(url: url, title: title, iconItemProvider: iconItemProvider)
  }
}
