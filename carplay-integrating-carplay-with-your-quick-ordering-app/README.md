# Integrating CarPlay with your quick-ordering app

This sample code project demonstrates how to display custom ordering options in a vehicle using CarPlay. The sample app integrates with the CarPlay framework by implementing `CPTemplate` subclasses, such as [`CPPointOfInterestTemplate`](https://developer.apple.com/documentation/carplay/cppointofinteresttemplate) and [`CPListTemplate`](https://developer.apple.com/documentation/carplay/cplisttemplate). This sample's iOS app component provides a logging interface to help you understand the life cycle of a CarPlay app.

For more information about the app and how it works, see [Integrating CarPlay with your quick-ordering app](https://developer.apple.com/documentation/carplay/integrating-carplay-with-your-quick-ordering-app).


## Configure the sample code project

CarPlay quick-ordering apps require a CarPlay quick-ordering entitlement, which you can request [here](https://developer.apple.com/contact/carplay). After Apple grants the entitlement, follow these steps:

1. Log in to your account on the Apple Developer website and create a new provisioning profile that includes the CarPlay quick ordering-app entitlement.

2. Import the newly created provisioning profile into Xcode.

3. Create an `Entitlements.plist` file in the project, if you don't have one already. 

4. Create a key for the CarPlay quick-ordering app entitlement as a Boolean. Make sure that the target project setting `CODE_SIGN_ENTITLEMENTS` has the path of the `Entitlements.plist` file. 
