# SimpleURLFilter

SimpleURLFilter makes use of the NEURLFilterManager to demonstrate managing URL filtering configurations.

## Overview

URL filtering is achieved as a two step process in which request URLs are rapidly checked against local bloom filter data, and in the case of a potential match, a configured Private Information Retrieval (PIR) server is subsequently queried. PIR server data is cached locally, and is refreshed on a regular schedule. This results in a very fast filtering implementation, preserving user privacy, which is robust and continually refreshed with current filtering criteria. This mechanism is very similar to the [Live Caller ID Lookup](https://developer.apple.com/documentation/identitylookup/getting-up-to-date-calling-and-blocking-information-for-your-app) capabilities, so many of the concepts and technology overlap.

The bloom filter pre-filter is provided to the system through the use of an app extension protocol defined by NEURLFilterControlProvider.

NEURLFilterManager provides the means to manage the URL filtering configuration, including the PIR server URL, cache management, and refresh timing. Filtering status and configuration updates are available through async sequences.

This SimpleURLFilter sample application utilizes the interface presented by NEURLFilterManager to configure and manage URL filtering capabilities, and includes an implementation of the NEURLFilterControlProvider protocol in an embedded application extension. The extension implementation delivers bundled bloom filter data to the system.

## Configure the sample code project

Open the sample code project in Xcode. Before building it, do the following:

1. Set the developer team for all targets to your team so Xcode automatically manages the provisioning profile. For more information, see [Assign a project to a team](https://help.apple.com/xcode/mac/current/#/dev23aab79b4).

1. Optionally build and run the PIR server sample (or have your own server ready for use).

## PIR Server

A sample PIR Server service and configuration is included in the "PIR Server" directory. Please refer to the [README.md](./PIR%20Server/README.md).

## Get started

To see the sample app in action, use Xcode to build and run the app on your iOS device.

Running the sample project on device will allow you to configure and apply a URL filter.

The main view of the application shows status information about the currently installed filter, if there is one, and transient status messages from the application as various actions are performed.

Two main butons are prominent. The "Enable"/"Disable" button is a quick way to enable or disable the current filter configuration and is equivalent to saving the entire configuration after changing the `isEnabled` flag on the manager. The "Configure" button presents an interface to view and change the filter properties, and then apply them.

Within the configure interface are fields to enable/disable the configuration, specify a URL for the PIR server, optionally specify a URL for the Privacy Pass server, the Authentication token used with the PIR server, a picker to choose the pre-filter fetch frequency interval, and a toggle treat failures in the system as allowing or disallowing the requested URL by default.

The Privacy Pass server URL is optional in this context and if not specified, the system will assume the configured PIR server URL handles this responsibility as well (which is true of the sample server).

For example, if you decide to use the sample PIR server and have it running, you would:

* Toggle the "Enabled" switch to the on state.
* Set the "PIR Server URL" to `http://localhost:8080`
* Leave the "PIR Privacy Pass Issuer URL" empty.
* Populate the "Authentication Token" with `AAAA` (as indicated in the [`service-config.json`](PIR%20Server/service-config.json) file).
* Leave the "Pre-filter Fetch Frequency" at the default setting of "45 minutes"
* Toggle the "Fail Closed" switch to the on state.

Then use the "Apply" button to save these configuration changes and start the filter.

At this point you should be prompted to allow the filter, and if you choose to proceed you will enter the device password, and be taken into Settings to verify. You can then return to the application to check on the filter status and perform other actions.

## API Notes

The main interface to the `NEURLFilterManager` for this sample is the `ConfigurationModel` class in the `ConfigurationModel.swift` file. This is `@Observable` so changes here can allow the user interface to react.

The `NEURLFilterManager` is addressed through a Singleton presented via the static `shared` property, and maintains state internally for the filter configuration.

The configuration state of the `NEURLFilterManager` must be loaded from the system by calling `loadFromPreferences()` and the system needs to be informed of any changes made to the configuration state by calling `saveToPreferences()`. Additionally, the configuration can be removed from the system by calling the `removeFromPreferences()` function.

The `setConfiguration(pirServerURL:pirPrivacyPassIssuerURL:pirAuthenticationToken:controlProviderBundleIdentifier:)` function is used to set the required configuration properties, but you likely will also want to set values for the `prefilterFetchInterval`, `shouldFailClosed`, and `isEnabled` properties. Once configured as desired, be sure to call `saveToPreferences()` to inform the system of the changes.

Once an enabled configuration is set and saved the system will attempt to place it in a running state. You can directly query the filter state through the `NEURLFilterManager` `status` property, or use the `handleStatusChange()` async sequence API to be informed of status updates. Should the state be in an unexpected error state you can query the `lastDisconnectError` property for the most recent error, keeping in mind this error represents the most recently available error and may be a remnant from a previous issue, if nothing has caused a more recent error to overwrite it.

## See Also

* [Understanding how Live Caller ID Lookup preserves privacy](https://swiftpackageindex.com/apple/live-caller-id-lookup-example/main/documentation/pirservice/privacyexplanation)
* [Anonymous Authentication](https://swiftpackageindex.com/apple/live-caller-id-lookup-example/main/documentation/pirservice/authentication)
