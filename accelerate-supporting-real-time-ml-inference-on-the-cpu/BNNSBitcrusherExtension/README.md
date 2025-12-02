# Audio Unit Extension
This template serves as a starting point to create a custom plug-in using the latest audio unit standard (AUv3). The AUv3 standard builds on the App Extensions model, which means you deliver your plug-in as an extension contained within an app you distribute through the App Store or your own store.

There are five types of Audio Unit Extensions, and each type has a four-character code.

|Name|Four-character code|
|---|---|
|Effect|`aufx`|
|Music Effect|`aumf`|
|MIDI Processor|`aumi`|
|Instrument|`aumu`|
|Generator|`augn`|


## Languages
This template uses Swift and SwiftUI for business logic and user interface, C++ for real-time constrained areas, and Objective-C for interacting between Swift and C++.

## Project Layout
This template helps make audio unit development as easy as possible. In most cases, you only need to edit files in the top-level groups --- the `Parameters`, `DSP`, and `UI` groups.

* /Common - Contains common code according to functionality, which you rarely need to modify. 
	* `Audio Unit/BNNSBitcrusherExtensionAudioUnit.mm/h` - A subclass of `AUAudioUnit`, this is the actual audio unit implementation. In advanced cases, you may need to change this file to add additional functionality from `AUAudioUnit`.  
* /Parameters
	* `BNNSBitcrusherExtensionParameterAddresses.h` - A pure `C` enumeration containing parameter addresses that Swift and C++ use to reference parameters.
	
	* `Parameters.swift` - Contains a `ParameterTreeSpec` object consisting of `ParameterGroupSpec` and `ParameterSpec`, which allow you describe your plug-in's parameters and the layout of those parameters.

* /DSP
	* `BNNSBitcrusherExtensionDSPKernel.hpp` - A pure C++ class to handle the real-time aspects of the Audio Unit Extension. Perform DSP and processing here. Note: Be aware of the constraints of real-time audio processing. 
* /UI
	* `BNNSBitcrusherExtensionMainView.swift` - A SwiftUI-based main view. Add your SwiftUI views and controls here.

## Adding a parameter
1. Add a new parameter address to the `BNNSBitcrusherExtensionParameterAddress` enumeration in `BNNSBitcrusherExtensionParameterAddresses.h` 


Example:

```c
typedef NS_ENUM(AUParameterAddress, BNNSBitcrusherExtensionParameterAddress) {
	sendNote = 0,
	....
	attack
```

2. Create a `ParameterSpec` in `Parameters.swift` using the enumeration value (from step 1) as the address.

Example:

```swift
ParameterGroupSpec(identifier: "global", name: "Global") {
	....
	ParameterSpec(
		address: .attack,
		identifier: "attack",
		name: "Attack",
		units: .milliseconds,
		valueRange: 0.0...1000.0,
		defaultValue: 100.0
	)
	...
```
Note: The system uses the identifier to interact with this parameter from SwiftUI.

3. To manipulate the DSP side of the audio unit, you need to handle changes to the new parameter in `BNNSBitcrusherExtensionDSPKernel.hpp`. In the `setParameter` and `getParameter` methods, add a case for the new parameter address.

Example:

```cpp
	void setParameter(AUParameterAddress address, AUValue value) {
		switch (address) {
			....
			case BNNSBitcrusherExtensionExtensionParameterAddress:: attack:
				mAttack = value;
				break;			
			...
	}
	
	AUValue getParameter(AUParameterAddress address) {
		switch (address) {
			....
			case BNNSBitcrusherExtensionExtensionParameterAddress::attack:
				return (AUValue) mAttack;
			...
	}
	
	// You can now apply attack to your DSP algorithm using `mAttack` in the `process` call. 
```

4. For audio units that present a user interface, expose or access the new parameter in your SwiftUI view. You can access the parameter using its identifier (from step 2). Access it using dot notation as follows: `parameterTree.<ParameterGroupSpec Identifier>.<ParameterGroupSpec Identifier>.<ParameterSpec Identifier>`

Example

```Swift
// Access the attack parameters value from SwiftUI.
parameterTree.global.attack.value

// Set the attack parameters value from SwiftUI.
parameterTree.global.attack.value = 0.5

// Bind the parameter to a slider.
struct EqualizerExtensionMainView: View {
	...	
	var body: some View {
		ParameterSlider(param: parameterTree.global.attack)
	}
	...
}

/*
Note: The `parameterTree.<parameter_name>` needs to match the structure and identifier of the parameter you define in `Parameters.swift`.
*/
```

## Mac Catalyst, iPhone, and iPad apps on Mac with Apple silicon

To build this template in a Mac Catalyst or iPhone/iPad app on Mac with Apple silicon, perform the following steps:  
1. Select your Xcode project in the Project navigator.
2. Select your app target under the Targets menu.
3. Under Deployment Info, select Mac Catalyst. (Skip this step for iPhone and iPad apps on Mac with Apple silicon.)
4. Click the General tab in the menu bar.
5. Under Frameworks, Libraries, and Embedded Content, click the button next to the iOS filter.
6. In the pop-up menu, select "Allow any platforms".

## More information
[Apple Audio Developer Documentation](https://developer.apple.com/audio/)
