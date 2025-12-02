# Integrating a Toolbar and Touch Bar into Your App

Provide users quick access to your app's features from a toolbar and corresponding Touch Bar.

## Overview

The *toolbar* appears in the space immediately below or next to a window's title bar and above the app's content. You use an [`NSToolbar`](https://developer.apple.com/documentation/appkit/nstoolbar) object to manage the items that appear in a toolbar, which are [`NSToolbarItem`](https://developer.apple.com/documentation/appkit/nstoolbaritem) objects created in Interface Builder or source code.

This sample shows you how to add a toolbar to a window and add Touch Bar support that works in conjunction with the toolbar.

## Add the Toolbar

The sample defines the custom class `WindowController`, which derives from [`NSWindowController`](https://developer.apple.com/documentation/appkit/nswindowcontroller) and conforms to the [`NSToolbarDelegate`](https://developer.apple.com/documentation/appkit/nstoolbardelegate) protocol. In Interface Builder, the sample creates an instance of `WindowController` in the Window Controller Scene of `Main.storyboard`, and adds an [`NSToolbar`](https://developer.apple.com/documentation/appkit/nstoolbar) object to the [`window`](https://developer.apple.com/documentation/appkit/nswindowcontroller/window) referenced by the controller. Then the sample connects the toolbar's [`delegate`](https://developer.apple.com/documentation/appkit/nstoolbar/delegate) to the `WindowController` instance.

The window controller also defines an outlet variable `toolbar`, making it possible to reference the toolbar instance in the source code of `WindowController.swift`.

## Create Toolbar Item Identifiers

Each [`NSToolbarItem`](https://developer.apple.com/documentation/appkit/nstoolbaritem) object has a unique identifier of type [`NSToolbarItem.Identifier`](https://developer.apple.com/documentation/appkit/nstoolbaritem/identifier). AppKit provides identifiers for standard toolbar items such as cloud sharing, printing, and showing the font and color palette. For custom toolbar items, the app provides the identifiers. For example, the sample provides two identifiers for its custom toolbar items: one for setting the font size and one for setting the font style of an [`NSTextView`](https://developer.apple.com/documentation/appkit/nstextview).

## Specify Allowed Toolbar Items

To tell the toolbar which items are available, the sample's toolbar delegate implements the [`toolbarAllowedItemIdentifiers(_:)`](https://developer.apple.com/documentation/appkit/nstoolbardelegate/toolbarAllowedItemIdentifiers(_:)) method, which returns an array of item identifiers. The available items appear in the toolbar's customization palette for customizing the toolbar when running the sample app.

## Specify Default Toolbar Items

When the sample app launches for the first time, a default set of items appear in the toolbar. The sample provides these items by implementing the [`toolbarDefaultItemIdentifiers(_:)`](https://developer.apple.com/documentation/appkit/nstoolbardelegate/toolbarDefaultItemIdentifiers(_:)) delegate method, which returns an array containing the font style and font size item identifiers. 

## Create a Toolbar Item from an Identifier

The toolbar asks its delegate to create a toolbar item by calling the [`toolbar(_:itemForItemIdentifier:willBeInsertedIntoToolbar:)`](https://developer.apple.com/documentation/appkit/nstoolbardelegate/toolbar(_:itemForItemIdentifier:willBeInsertedIntoToolbar:)) method. It calls this method when adding an item to the toolbar but also when adding items to the toolbar's customization palette.

The sample app's implementation of this method creates items for the two identifiers created in the app, font style and font size. 

The delegate isn't responsible for creating toolbar items for standard identifiers; AppKit creates those toolbar items.

## Use a Custom View for a Toolbar Item

The font style and font size toolbar items display a custom view that the sample defines in `Main.storyboard` and connects with outlets in `WindowController`.

When the toolbar calls the delegate method [`toolbar(_:itemForItemIdentifier:willBeInsertedIntoToolbar:)`](https://developer.apple.com/documentation/appkit/nstoolbardelegate/toolbar(_:itemForItemIdentifier:willBeInsertedIntoToolbar:)), the sample creates the toolbar item by calling its helper function `customToolbarItem`, passing in the custom view for the requested toolbar item.

## Add More Attributes to a Toolbar Item

The sample's toolbar delegate also implements the [`toolbarWillAddItem(_:)`](https://developer.apple.com/documentation/appkit/nstoolbardelegate/toolbarWillAddItem(_:)) method to know when the toolbar is about to add an item. This gives the delegate the opportunity to add or change state information for the item. For example, the sample sets the [`toolTip`](https://developer.apple.com/documentation/appkit/nstoolbaritem/toolTip) property of a toolbar item with the [`.print`](https://developer.apple.com/documentation/appkit/nstoolbaritem/identifier/print) identifier.

## Provide Toolbar Customization to Users

The toolbar displays the default items in the same order as they appear in the array that [`toolbarDefaultItemIdentifiers(_:)`](https://developer.apple.com/documentation/appkit/nstoolbardelegate/toolbarDefaultItemIdentifiers(_:)) returns. But users can rearrange the items, add and remove items, and reset the toolbar to its default items by selecting View \> Customize Toolbar, which displays the toolbar's configuration palette. The sample app also saves the changes and reapplies them the next time the user launches the app. 

The sample app provides these behaviors by setting the toolbar's [`allowsUserCustomization`](https://developer.apple.com/documentation/appkit/nstoolbar/allowsUserCustomization) and [`autosavesConfiguration`](https://developer.apple.com/documentation/appkit/nstoolbar/autosavesConfiguration) properties to `true`.

## Add Touch Bar Support

The sample app provides Touch Bar support that works in conjunction with the toolbar. Like the toolbar, the app provides two items on the Touch Bar: font style and font size.

Before the sample app can add items to the Touch Bar, it needs to create an [`NSTouchBar`](https://developer.apple.com/documentation/appkit/nstouchbar) object. The sample does this by overriding the [`makeTouchBar()`](https://developer.apple.com/documentation/appkit/nsresponder/makeTouchBar()) method, where it creates and returns a new Touch Bar object. 

Then, similar to adding toolbar items, the sample implements the [`NSTouchBarDelegate`](https://developer.apple.com/documentation/appkit/nstouchbardelegate) method [`touchBar(_:makeItemForIdentifier:)`](https://developer.apple.com/documentation/appkit/nstouchbardelegate/touchBar(_:makeItemForIdentifier:)), where it creates and returns Touch Bar items for the specified identifier.

- Note: It's possible to simulate a Touch Bar from Xcode by choosing Window > Show Touch Bar.

## Provide Touch Bar Customization to Users

As with the toolbar, the sample app lets users customize items in the Touch Bar by choosing View \> Customize Touch Bar. The app provides this feature by setting the [`isAutomaticCustomizeTouchBarMenuItemEnabled`](https://developer.apple.com/documentation/appkit/nsapplication/isAutomaticCustomizeTouchBarMenuItemEnabled) property to `true`.
