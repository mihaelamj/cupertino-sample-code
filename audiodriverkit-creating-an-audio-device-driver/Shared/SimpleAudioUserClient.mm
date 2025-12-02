/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the Objective-C bridging class, which manages
			 communications between user clients and the audio device.
*/

#import "SimpleAudioUserClient.h"
#import "SimpleAudioDriverKeys.h"

@interface SimpleAudioUserClient()
@property IONotificationPortRef mIOKitNotificationPort;
@property io_object_t ioObject;
@property io_connect_t ioConnection;
@end

@implementation SimpleAudioUserClient

#if TARGET_OS_OSX
#import <CoreAudio/CoreAudio.h>
#import <CoreAudio/AudioServerPlugIn.h>
#import <vector>

// The CoreAudio framework and custom property API is only available in macOS.
// Validate the device's custom properties by checking the data types, selector,
// qualifier, and data value.
- (OSStatus)checkDeviceCustomProperties
{
	OSStatus err = kAudioHardwareNoError;
	try
	{
		AudioObjectPropertyAddress prop_addr = {kAudioHardwarePropertyDevices, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain};
		
		prop_addr = {kAudioHardwarePropertyTranslateUIDToDevice, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain};
		auto device_uid = CFSTR(kSimpleAudioDriverDeviceUID);
		AudioObjectID device_id = kAudioObjectUnknown;
		UInt32 out_size = sizeof(AudioObjectID);
		auto err = AudioObjectGetPropertyData(kAudioObjectSystemObject, &prop_addr, sizeof(CFStringRef), &device_uid, &out_size, &device_id);
		if (err)
		{
			throw std::runtime_error("Failed to get SimpleAudioDevice by uid");
		}
		
		prop_addr = {kAudioObjectPropertyCustomPropertyInfoList, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain};
		err = AudioObjectGetPropertyDataSize(device_id, &prop_addr, 0, nullptr, &out_size);
		if (err)
		{
			throw std::runtime_error("Failed to get custom property list size");
		}
		
		auto num_items = out_size/sizeof(AudioServerPlugInCustomPropertyInfo);
		std::vector<AudioServerPlugInCustomPropertyInfo> custom_prop_list(num_items);
		err = AudioObjectGetPropertyData(device_id, &prop_addr, 0, nullptr, &out_size, custom_prop_list.data());
		if (err)
		{
			throw std::runtime_error("Failed to get custom property list");
		}
		num_items = out_size / sizeof(AudioServerPlugInCustomPropertyInfo);
		custom_prop_list.resize(num_items);
		if (num_items != 1)
		{
			throw std::runtime_error("Should only have one custom property on the SimpleAudioDevice");
		}
		
		AudioServerPlugInCustomPropertyInfo custom_prop_info = custom_prop_list.front();
		if (custom_prop_info.mSelector != kSimpleAudioDriverCustomPropertySelector)
		{
			throw std::runtime_error("Custom property selector is incorrect");
		}
		if (custom_prop_info.mQualifierDataType != kAudioServerPlugInCustomPropertyDataTypeCFString)
		{
			throw std::runtime_error("Custom property qualifier type is incorrect");
		}
		if (custom_prop_info.mPropertyDataType != kAudioServerPlugInCustomPropertyDataTypeCFString)
		{
			throw std::runtime_error("Custom property data type is incorrect");
		}

		std::vector<std::pair<CFStringRef, CFStringRef>> custom_prop_qualifier_data_pair = {
			{ CFSTR(kSimpleAudioDriverCustomPropertyQualifier0), CFSTR(kSimpleAudioDriverCustomPropertyDataValue0) },
			{ CFSTR(kSimpleAudioDriverCustomPropertyQualifier1), CFSTR(kSimpleAudioDriverCustomPropertyDataValue1) },
		};
		
		prop_addr = { custom_prop_info.mSelector, kAudioObjectPropertyScopeGlobal, kAudioObjectPropertyElementMain };
		for (const auto &[qualifier, data] : custom_prop_qualifier_data_pair)
		{
			CFStringRef custom_prop_data = nullptr;
			UInt32 the_size = sizeof(CFStringRef);
			err = AudioObjectGetPropertyData(device_id, &prop_addr, sizeof(CFStringRef), &qualifier, &the_size, &custom_prop_data);
			if (err)
			{
				throw std::runtime_error("Error getting custom property value");
			}
			CFComparisonResult compare_result = CFStringCompare(data, custom_prop_data, kCFCompareCaseInsensitive);
			if (compare_result != kCFCompareEqualTo)
			{
				throw std::runtime_error("Custom property data is incorrect");
			}
			CFRelease(custom_prop_data);
		}
	}
	catch(...)
	{
		NSLog(@"Caught exception trying to validate custom properties.");
	}
	return err;
}
#endif

// Open a user client instance, which initiates communication with the driver.
- (NSString*) open
{
	if (_ioObject == IO_OBJECT_NULL && _ioConnection == IO_OBJECT_NULL)
	{
		// Get the IOKit main port.
		mach_port_t theMainPort = MACH_PORT_NULL;
		kern_return_t theKernelError = IOMainPort(bootstrap_port, &theMainPort);
		if (theKernelError != kIOReturnSuccess)
		{
			return @"Failed to get IOMainPort.";
		}

		// Create a matching dictionary for the driver class. Note that classes
		// published by a dext need to be matched by class name rather than
		// other methods. So be sure to use IOServiceNameMatching rather than
		// IOServiceMatching to construct the dictionary.
		CFDictionaryRef theMatchingDictionary = IOServiceNameMatching(kSimpleAudioDriverClassName);
		io_service_t matchedService = IOServiceGetMatchingService(theMainPort, theMatchingDictionary);
		if (matchedService)
		{
			_ioObject = matchedService;
			theKernelError = IOServiceOpen(_ioObject, mach_task_self(), 0, &_ioConnection);
			if (theKernelError == kIOReturnSuccess)
			{
#if TARGET_OS_OSX
				OSStatus error = [self checkDeviceCustomProperties];
				if (error)
				{
					return @"Connection to user client succeeded, but custom properties could not be validated";
				}
#endif
				return @"Connection to user client succeeded";
			}
			else
			{
				_ioObject = IO_OBJECT_NULL;
				_ioConnection = IO_OBJECT_NULL;
				return [NSString stringWithFormat:@"Failed to open user client connection, error:%u.", theKernelError];
			}
		}
		return @"Driver Extension is not running";
	}
	return @"User client is already connected";
}

// Instructs the user client to toggle the driver's data source,
// which changes the generated sine tone's frequency or goes into loopback mode.
- (NSString*)toggleDataSource
{
	if (_ioConnection == IO_OBJECT_NULL)
	{
		return @"Cannot toggle data source since user client is not connected";
	}
	
	// Call the custom user client method to toggle the data source directly on the driver extension.
	// This results in the CoreAudio HAL updating the selector control, and listeners (such
	// as Audio MIDI Setup) receive a properties changed notification.
	kern_return_t error = IOConnectCallMethod(_ioConnection,
											  static_cast<uint64_t>(SimpleAudioDriverExternalMethod_ToggleDataSource),
											  nullptr, 0, nullptr, 0, nullptr, nullptr, nullptr, 0);
	if (error != kIOReturnSuccess)
	{
		return [NSString stringWithFormat:@"Failed to toggle data source, error:%u.", error];
	}
	return @"Successfully toggle the data source";
}

// Instructs the user client to perform a configuration change, which toggles
// the device's sample rate.
- (NSString*)toggleRate
{
	if (_ioConnection == IO_OBJECT_NULL)
	{
		return @"Cannot toggle device sample rate since user client is not connected.";
	}
	
	// Call the custom user client method to change the test config change mechanism,
	// which toggles the device's sample rate.
	kern_return_t error = IOConnectCallMethod(_ioConnection,
											  static_cast<uint64_t>(SimpleAudioDriverExternalMethod_TestConfigChange),
											  nullptr, 0, nullptr, 0, nullptr, nullptr, nullptr, 0);
	if (error != kIOReturnSuccess)
	{
		return [NSString stringWithFormat:@"Failed to toggle device sample rate, error:%u.", error];
	}
	return @"Successfully toggle the device sample rate";
}
@end
