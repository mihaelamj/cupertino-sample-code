/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A file that defines the data model.
*/

import UIKit

struct UserActivity {
    // 'NSUserActivity' types for each window scene session:
    static let GalleryOpenDetailActivityType = "com.apple.gallery.openDetail" // Open activity via drag and drop.
    static let GalleryOpenInspectorActivityType = "com.apple.gallery.openInspector" // Open activity via button or context menu.
    
    // 'NSUserActivity' userInfo keys:
    static let GalleryOpenDetailPhotoAssetKey = "photoAsset" // Key to the photo's asset name.
    static let GalleryOpenDetailPhotoTitleKey = "photoTitle" // Key to the photo's title.
}

public struct Photo {
    
    let assetName: String
    let title: String
    
    var targetContentIdentifierAsset: String {
        get {
            return "\(InspectorSceneDelegate.inspectorSceneTargetContentIdentifier)-\(assetName)"
        }
    }

    var activityUserInfo: [String: Any] {
        get {
            return [UserActivity.GalleryOpenDetailPhotoAssetKey: assetName,
                    UserActivity.GalleryOpenDetailPhotoTitleKey: title]
        }
    }

    var detailUserActivity: NSUserActivity {
        /** Create an 'NSUserActivity' from the photo model.
            Note: This is used for drag and drop, so the 'activityType' string below must be included
            in the 'Info.plist' file under the 'NSUserActivityTypes' array.
        */
        let userActivity = NSUserActivity(activityType: UserActivity.GalleryOpenDetailActivityType)
        userActivity.userInfo = activityUserInfo
        userActivity.targetContentIdentifier = targetContentIdentifierAsset
        return userActivity
    }
    
    var inspectorUserActivity: NSUserActivity {
        /** Create an 'NSUserActivity' from the photo model.
            Note: This is used to create a second scene as an inspector.
        */
        let userActivity = NSUserActivity(activityType: UserActivity.GalleryOpenInspectorActivityType)
        userActivity.userInfo = activityUserInfo
        userActivity.targetContentIdentifier = targetContentIdentifierAsset
        return userActivity
    }

}

struct PhotoManager {
    static let shared = PhotoManager()
    let photos = [
        Photo(assetName: "1.jpg", title: "Sunrise"),
        Photo(assetName: "2.jpg", title: "Sunset"),
        Photo(assetName: "3.jpg", title: "Artichokes"),
        Photo(assetName: "4.jpg", title: "Walnuts"),
        Photo(assetName: "5.jpg", title: "Cherries"),
        Photo(assetName: "6.jpg", title: "Forest"),
        Photo(assetName: "7.jpg", title: "City Skyline")
    ]
}

