# Supporting multiple windows on iPad

Support side-by-side instances of your app's interface and create new windows.

## Overview

This sample shows how to create multiple windows that give users the ability to create separate parts of your application with similar or varying content. Windows are managed by a scene or [`UISceneSession`](https://developer.apple.com/documentation/uikit/uiscenesession) class. Your application uses [`UISceneDelegate`](https://developer.apple.com/documentation/uikit/uiscenedelegate) and [`UISceneConfiguration`](https://developer.apple.com/documentation/uikit/uisceneconfiguration) to manage the life cycle of a window. Scenes have their own dedicated lifecycle that are managed separate from [`UIApplication`](https://developer.apple.com/documentation/uikit/uiapplication).

When you adopt a multi-window architecture, the [`UIApplicationDelegate`](https://developer.apple.com/documentation/uikit/uiapplicationdelegate) class that manages your application manages newly created scenes. Then, `UISceneDelegate` replaces the code in the delegate functions of `UIApplicationDelegate`.

UIKit provides a subclass of `UISceneDelegate` called [`UIWindowSceneDelegate`](https://developer.apple.com/documentation/uikit/uiwindowscenedelegate) designed specifically to help manage your windows. When adopting the multi-window architecture in an existing application running on iOS 12 or earlier, you move more responsibility from `UIApplicationDelegate` to `UIWindowSceneDelegate`.

For more information on multiple windows in an iPadOS app, refer to [Human Interface Guidelines for iOS](https://developer.apple.com/design/human-interface-guidelines/ios/system-capabilities/multiple-windows/).

- Note: This sample code project was discussed and demonstrated at WWDC 2019 session 212: [Introducing Multiple Windows on iPad](https://developer.apple.com/videos/play/wwdc2019/212).

## Configure the sample code project

In Xcode, select your development team on the iOS target's Signing & Capabilities tab.

## Add multiple scene support

To support multiple windows, the app's `Info.plist` requires a manifest or [`UIApplicationSceneManifest`](https://developer.apple.com/documentation/bundleresources/information_property_list/uiapplicationscenemanifest), which contains information about the app's scene-based life-cycle support. The presence of this key indicates that the app supports scenes and doesn't use an app delegate object to manage transitions to and from the foreground or background. Include the key [`UIApplicationSupportsMultipleScenes`](https://developer.apple.com/documentation/bundleresources/information_property_list/uiapplicationscenemanifest/uiapplicationsupportsmultiplescenes), with its Boolean value set to `true`, which indicates that the app support two or more scenes simultaneously.

## Add a scene delegate

This sample provides a `UIWindowScene` subclass called `SceneDelegate` to manage the app's primary window scene. The [`scene(_:willConnectTo:options:)`](https://developer.apple.com/documentation/uikit/uiscenedelegate/scene(_:willConnectTo:options:)) delegate function sets up the window and content.

``` swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    if let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity {
        if !configure(window: window, with: userActivity) {
            Swift.debugPrint("Failed to restore from \(userActivity)")
        }
    }
    // The 'window' property will automatically be loaded with the storyboard's initial view controller.
    
    // Set the activation predicates, which operate on the 'targetContentIdentifier'.
    let conditions = scene.activationConditions
    let prefsPredicate = NSPredicate(format: "self == %@", mainSceneTargetContentIdentifier)
    // The main predicate, which expresses to the system what kind of content the scene can display.
    conditions.canActivateForTargetContentIdentifierPredicate = prefsPredicate
    // The secondary predicate, which expresses to the system that this scene is especially interested in a particular kind of content.
    conditions.prefersToActivateForTargetContentIdentifierPredicate = prefsPredicate
}
```

By using the [`UISceneConfigurations`](https://developer.apple.com/documentation/bundleresources/information_property_list/uiapplicationscenemanifest/uisceneconfigurations) key in the `Info.plist` scene manifest, the sample's window for this scene is automatically configured and its root view controller is loaded from the storyboard.

## Restore a scene

When it's time to restore a scene, iOS calls your delegate `scene(_:willConnectTo:options:)`. The sample app restores the scene to its previous state through the use of [`NSUserActivity`](https://developer.apple.com/documentation/foundation/nsuseractivity).

``` swift
func configure(window: UIWindow?, with activity: NSUserActivity) -> Bool {
    var configured = false

    guard activity.activityType == UserActivity.GalleryOpenDetailActivityType else { return configured }
    guard let navigationController = window?.rootViewController as? UINavigationController else { return configured }
        
    if let photoID = activity.userInfo?[UserActivity.GalleryOpenDetailPhotoAssetKey] as? String,
        let photoTitle = activity.userInfo?[UserActivity.GalleryOpenDetailPhotoTitleKey] as? String {
        // Restore the view controller with the 'photoID' and 'photoTitle'.
        if let photoDetailViewController = PhotoDetailViewController.loadFromStoryboard() {
            photoDetailViewController.photo = Photo(assetName: photoID, title: photoTitle)

            navigationController.pushViewController(photoDetailViewController, animated: false)
            configured = true
        }
    }
    return configured
}
```

## Create multiple windows from drag and drop

This sample creates a separate window when the user drags an image from the collection view to the left or right side of the iPad screen. The sample creates a new window by implementing the `UICollectionViewDragDelegate` function [`collectionView(_:itemsForBeginning:at:)`](https://developer.apple.com/documentation/uikit/uicollectionviewdragdelegate/collectionView(_:itemsForBeginning:at:)) and providing a [`UIDragItem`](https://developer.apple.com/documentation/uikit/uidragitem) with an associated [`NSItemProvider`](https://developer.apple.com/documentation/foundation/nsitemprovider). Then, the sample passes the photo data to the new window scene with a registered `NSUserActivity`.

``` swift
func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
    var dragItems = [UIDragItem]()
    let selectedPhoto = photos[indexPath.row]
    if let imageToDrag = UIImage(named: selectedPhoto.assetName) {
        let userActivity = selectedPhoto.detailUserActivity
        let itemProvider = NSItemProvider(object: imageToDrag)
        itemProvider.registerObject(userActivity, visibility: .all)

        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = selectedPhoto
        dragItems.append(dragItem)
    }
    return dragItems
}
```

The `NSUserActivity` [`activityType`](https://developer.apple.com/documentation/foundation/nsuseractivity/1409611-activitytype) must be included in the app's `Info.plist` under the [`NSUserActivityTypes`](https://developer.apple.com/documentation/bundleresources/information_property_list/nsuseractivitytypes) array. Without it, a separate window isn't created as the photo is dragged to the edge of the device.

```swift
    <key>NSUserActivityTypes</key>
    <array>
        <string>com.apple.gallery.openDetail</string>
    </array>
```

## Create multiple windows programmatically

This sample also creates a separate window scene programmatically, by responding to a user action:
- **iPadOS**: Tap and hold a photo and select the menu item Inspect. This creates a form sheet window with that photo. The form sheet can then be dragged to the left or right side of the iPad screen to split the app's interface in two.
- **macOS**: Select a photo. Click the Info toolbar button or command-click the photo and select Inspect. Both create a new window containing that photo.

Both approaches use the following code to create a new window scene.

``` swift
class func openInspectorSceneSessionForPhoto(_ photo: Photo, requestingScene: UIWindowScene, errorHandler: ((Error) -> Void)? = nil) {
    let options = UIWindowScene.ActivationRequestOptions()
    options.preferredPresentationStyle = .prominent
    options.requestingScene = requestingScene // The scene object that requested the activation of a different scene.
    
    // Present this scene as a secondary window separate from the main window.
    //
    // Look for an already open window scene session that matches the photo.
    if let foundSceneSession = InspectorSceneDelegate.activeInspectorSceneSessionForPhoto(photo.assetName) {
        // Inspector scene session already open, so activate it.
        UIApplication.shared.requestSceneSessionActivation(foundSceneSession, // Activate the found scene session.
                                                           userActivity: nil, // No need to pass activity for an already open session.
                                                           options: options,
                                                           errorHandler: errorHandler)
    } else {
        // No Inspector scene session found, so create a new one.
        let userActivity = photo.inspectorUserActivity

        UIApplication.shared.requestSceneSessionActivation(nil, // Pass nil means make a new one.
                                                           userActivity: userActivity,
                                                           options: options,
                                                           errorHandler: errorHandler)
    }
}
```

Through the use of a unique `NSUserActivity` [`activityType`](https://developer.apple.com/documentation/foundation/nsuseractivity/1409611-activitytype), the app can distinguish which new scene to create in [`application(_:configurationForConnecting:options:)`](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/application(_:configurationForConnecting:options:)):

``` swift
func application(_ application: UIApplication,
                 configurationForConnecting connectingSceneSession: UISceneSession,
                 options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // It's important that each UISceneConfiguration have a unique configuration name.
    var configurationName: String!

    switch options.userActivities.first?.activityType {
    case UserActivity.GalleryOpenInspectorActivityType:
        configurationName = "Inspector Configuration" // Create a photo inspector window scene.
    default:
        configurationName = "Default Configuration" // Create a default gallery window scene.
    }
    
    return UISceneConfiguration(name: configurationName, sessionRole: connectingSceneSession.role)
}
```
