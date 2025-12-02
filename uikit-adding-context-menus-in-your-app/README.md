# Adding context menus in your app

Provide quick access to useful actions by adding context menus to your iOS app.

## Overview

This sample project demonstrates how to add context menus to user-interface elements such as views, controls, table views, collection views, and web views. Apps enhance and extend context menus with actions, nested submenu actions, and custom previews. For more information on context menu design, see [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/ios/controls/context-menus/).

## Create a context menu

This sample shows two ways to create context menus:
1. For a [`UIView`](https://developer.apple.com/documentation/uikit/uiview), the sample creates a [`UIContextMenuInteraction`](https://developer.apple.com/documentation/uikit/uicontextmenuinteraction) object and attaches it to that view. The `UIContextMenuInteraction` object focuses the user's attention on a specific portion of the UI, and provides actions for the user to perform on that content. Then, the app adopts the [`UIContextMenuInteractionDelegate`](https://developer.apple.com/documentation/uikit/uicontextmenuinteractiondelegate) protocol and provides a [`UIContextMenuConfiguration`](https://developer.apple.com/documentation/uikit/uicontextmenuconfiguration) object.
2. For more specific UI elements like tables, collections, and web views, the app adopts specific protocols for those elements that return a `UIContextMenuConfiguration`.

Adopt `UIContextMenuInteractionDelegate` to manage the lifecycle of context menus. The app implements [`contextMenuInteraction(_:configurationForMenuAtLocation:)`](https://developer.apple.com/documentation/uikit/uicontextmenuinteractiondelegate/contextMenuInteraction(_:configurationForMenuAtLocation:)) to return a `UIContextMenuConfiguration` object. This configuration object consists of an optional `identifier`, a `previewProvider` that returns a [`UIViewController`](https://developer.apple.com/documentation/uikit/uiviewcontroller), and an `actionProvider` that returns a [`UIMenu`](https://developer.apple.com/documentation/uikit/uimenu) with a set of [`UIActions`](https://developer.apple.com/documentation/uikit/uiaction).

Context menus with rich content also provide a 
[`UITargetedPreview`](https://developer.apple.com/documentation/uikit/uitargetedpreview), an object that describes the source view when opening and animating the contextual menu. A `UITargetedPreview` specifies the view to use during animated transitions.

## Add a context menu to a view
This sample adds a context menu to a `UIView` by calling [`addInteraction(_:)`](https://developer.apple.com/documentation/uikit/uiview/addInteraction(_:)).

``` swift
let interaction = UIContextMenuInteraction(delegate: self)
imageView.addInteraction(interaction)
```

When the user touches and holds on that view, the view asks its delegate to provide the context menu by calling `contextMenuInteraction(_:configurationForMenuAtLocation:)`.

``` swift
func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                            configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
    return UIContextMenuConfiguration(identifier: nil,
                                      previewProvider: nil,
                                      actionProvider: {
            suggestedActions in
        let inspectAction =
            UIAction(title: NSLocalizedString("InspectTitle", comment: ""),
                     image: UIImage(systemName: "arrow.up.square")) { action in
                self.performInspect()
            }
            
        let duplicateAction =
            UIAction(title: NSLocalizedString("DuplicateTitle", comment: ""),
                     image: UIImage(systemName: "plus.square.on.square")) { action in
                self.performDuplicate()
            }
            
        let deleteAction =
            UIAction(title: NSLocalizedString("DeleteTitle", comment: ""),
                     image: UIImage(systemName: "trash"),
                     attributes: .destructive) { action in
                self.performDelete()
            }
                                        
        return UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
    })
}
```

## Add a context menu to a table view
This sample adds a context menu to a [`UITableView`](https://developer.apple.com/documentation/uikit/uitableview) when the user touches and holds a [`UITableViewCell`](https://developer.apple.com/documentation/uikit/uitableviewcell). `UITableView` asks its delegate to provide the context menu by calling [`tableView(_:contextMenuConfigurationForRowAt:point:)`](https://developer.apple.com/documentation/uikit/uitableviewdelegate/tableView(_:contextMenuConfigurationForRowAt:point:)).

``` swift
override func tableView(_ tableView: UITableView,
                        contextMenuConfigurationForRowAt indexPath: IndexPath,
                        point: CGPoint) -> UIContextMenuConfiguration? {
    return UIContextMenuConfiguration(identifier: nil,
                                      previewProvider: nil,
                                      actionProvider: {
            suggestedActions in
        let inspectAction =
            UIAction(title: NSLocalizedString("InspectTitle", comment: ""),
                     image: UIImage(systemName: "arrow.up.square")) { action in
                self.performInspect(indexPath)
            }
        let duplicateAction =
            UIAction(title: NSLocalizedString("DuplicateTitle", comment: ""),
                     image: UIImage(systemName: "plus.square.on.square")) { action in
                self.performDuplicate(indexPath)
            }
        let deleteAction =
            UIAction(title: NSLocalizedString("DeleteTitle", comment: ""),
                     image: UIImage(systemName: "trash"),
                     attributes: .destructive) { action in
                self.performDelete(indexPath)
            }
        return UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
    })
}
```

## Add a context menu to a collection view
This sample adds a context menu to a [`UICollectionView`](https://developer.apple.com/documentation/uikit/uicollectionview) when the user touches and holds a [`UICollectionViewCell`](https://developer.apple.com/documentation/uikit/uicollectionviewcell). `UICollectionView` asks its delegate to provide the context menu by calling [`collectionView(_:contextMenuConfigurationForItemAt:point:)`](https://developer.apple.com/documentation/uikit/uicollectionviewdelegate/collectionView(_:contextMenuConfigurationForItemAt:point:)).

``` swift
override func collectionView(_ collectionView: UICollectionView,
                             contextMenuConfigurationForItemAt indexPath: IndexPath,
                             point: CGPoint) -> UIContextMenuConfiguration? {
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
        let inspectAction = self.inspectAction(indexPath)
        let duplicateAction = self.duplicateAction(indexPath)
        let deleteAction = self.deleteAction(indexPath)
        return UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
    }
}
```

## Add a context menu to a control
This sample adds a context menu to a [`UIControl`](https://developer.apple.com/documentation/uikit/uicontrol). UIKit attaches a context menu to a `UIControl` in two different ways:

* By setting the `menu` property with a `UIMenu` object

``` swift
let inspectAction = self.inspectAction()
let duplicateAction = self.duplicateAction()
let deleteAction = self.deleteAction()
buttonMenuAsPrimary.menu = UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
buttonMenuAsPrimary.showsMenuAsPrimaryAction = true
```

* By adding a `UIContextMenuInteraction` object

``` swift
let interaction = UIContextMenuInteraction(delegate: self)
buttonMenu.addInteraction(interaction)
```

When the user touches and holds on that control, the app asks its delegate to provide a context menu by calling [`contextMenuInteraction(_:configurationForMenuAtLocation:)`](https://developer.apple.com/documentation/uikit/uicontextmenuinteractiondelegate/contextMenuInteraction(_:configurationForMenuAtLocation:))

``` swift
func contextMenuInteraction(_ interaction: UIContextMenuInteraction,
                            configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
    return UIContextMenuConfiguration(identifier: nil,
                                      previewProvider: nil,
                                      actionProvider: {
            suggestedActions in
        // Use the ContextMenu protocol to produce the UIActions.
        let inspectAction = self.inspectAction()
        let duplicateAction = self.duplicateAction()
        let deleteAction = self.deleteAction()
        return UIMenu(title: "", children: [inspectAction, duplicateAction, deleteAction])
    })
}
```

## Add a context menu to a web view
Select the Basic test case from the sample's Web Views outline item. When the user touches and holds on the link within the [`WKWebView`](https://developer.apple.com/documentation/webkit/wkwebview), the app presents a [`SFSafariViewController`](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller) to show that link content with a set of default `UIAction` items. When the user touches the view controller, the user moves out of the app and into Safari.

Select the Preview Provider test case from the sample's Web Views outline item. When the user touches and holds on the link within the `WKWebView`, the app presents a custom view controller.

This sample intercepts and adds to that context menu by adopting the [`WKUIDelegate`](https://developer.apple.com/documentation/webkit/wkuidelegate) protocol. `WKWebView` asks its delegate to provide the context menu by calling [`webView(_:contextMenuConfigurationForElement:completionHandler:)`](https://developer.apple.com/documentation/webkit/wkuidelegate/3335220-webview).

``` swift
func webView(_ webView: WKWebView,
             contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
             completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
    let configuration =
        UIContextMenuConfiguration(identifier: nil,
                                   previewProvider: { return SFSafariViewController(url: elementInfo.linkURL!) },
                                   actionProvider: { elements in
            guard elements.isEmpty == false else { return nil }
                                    
            // Add our custom action to the existing actions passed in.
            var elementsToUse = elements
            let inspectAction = self.extraAction(elementInfo.linkURL!)
            let editMenu = UIMenu(title: "", options: .displayInline, children: [inspectAction])
            elementsToUse.append(editMenu)
                   
            let contextMenuTitle = elementInfo.linkURL?.lastPathComponent
            return UIMenu(title: contextMenuTitle!, image: nil, identifier: nil, options: [], children: elementsToUse)
        }
    )
    completionHandler(configuration)
}
```
