/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of an AudioDriverKit device that generates a
             sine wave.
*/

// Local Includes
#include "SimpleAudioDevice.h"
#include "SimpleAudioDriver.h"
#include "SimpleAudioDriverKeys.h"

// AudioDriverKit Includes
#include <AudioDriverKit/AudioDriverKit.h>

// System Includes
#include <math.h>
#include <DriverKit/DriverKit.h>

#define kSampleRate_1 44100.0
#define kSampleRate_2 48000.0

#define kToneGenerationBufferFrameSize 512

#define kNumInputDataSources 3

struct SimpleAudioDevice_IVars
{
	OSSharedPtr<IOUserAudioDriver>	m_driver;
	OSSharedPtr<IODispatchQueue>	m_work_queue;
	
	uint64_t	m_zts_host_ticks_per_buffer;
	
	IOUserAudioStreamBasicDescription		m_stream_format;

	OSSharedPtr<IOUserAudioStream>			m_output_stream;
	OSSharedPtr<IOMemoryMap>				m_output_memory_map;

	OSSharedPtr<IOUserAudioStream>			m_input_stream;
	OSSharedPtr<IOMemoryMap>				m_input_memory_map;
	
	OSSharedPtr<IOUserAudioLevelControl>	m_input_volume_control;
	OSSharedPtr<IOUserAudioSelectorControl> m_input_selector_control;
	IOUserAudioSelectorValueDescription 	m_data_sources[kNumInputDataSources];
	
	OSSharedPtr<IOTimerDispatchSource>		m_zts_timer_event_source;
	OSSharedPtr<OSAction>					m_zts_timer_occurred_action;
		
	uint64_t	m_tone_sample_index;
};

bool SimpleAudioDevice::init(IOUserAudioDriver* in_driver,
						   bool in_supports_prewarming,
						   OSString* in_device_uid,
						   OSString* in_model_uid,
						   OSString* in_manufacturer_uid,
						   uint32_t in_zero_timestamp_period)
{
	auto success = super::init(in_driver, in_supports_prewarming, in_device_uid, in_model_uid, in_manufacturer_uid, in_zero_timestamp_period);
	if (!success)
	{
		return false;
	}
	ivars = IONewZero(SimpleAudioDevice_IVars, 1);
	if (ivars == nullptr)
	{
		return false;
	}
	
	IOOperationHandler io_operation = nullptr;
	IOReturn error = kIOReturnSuccess;
	
	ivars->m_driver = OSSharedPtr(in_driver, OSRetain);
	ivars->m_work_queue = GetWorkQueue();
	
	IOTimerDispatchSource* zts_timer_event_source = nullptr;
	OSAction* zts_timer_occurred_action = nullptr;
	
	OSSharedPtr<OSString> output_stream_name = OSSharedPtr(OSString::withCString("SimpleOutputStream"), OSNoRetain);

	OSSharedPtr<OSString> input_stream_name = OSSharedPtr(OSString::withCString("SimpleInputStream"), OSNoRetain);
	OSSharedPtr<OSString> input_volume_control_name = OSSharedPtr(OSString::withCString("SimpleInputVolumeControl"), OSNoRetain);
	OSSharedPtr<OSString> input_data_source_control = OSSharedPtr(OSString::withCString("Input Tone Frequency Control"), OSNoRetain);

	// Custom property information.
	/// - Tag: CreateCustomProperty
	IOUserAudioObjectPropertyAddress prop_addr = {
		kSimpleAudioDriverCustomPropertySelector,
		IOUserAudioObjectPropertyScope::Global,
		IOUserAudioObjectPropertyElementMain };
	OSSharedPtr<IOUserAudioCustomProperty> custom_property = nullptr;
	OSSharedPtr<OSString> qualifier = nullptr;
	OSSharedPtr<OSString> data = nullptr;

	// Configure the device and add stream objects.
	auto data_source_0 = OSSharedPtr(OSString::withCString("Sine Tone 440"), OSNoRetain);
	auto data_source_1 = OSSharedPtr(OSString::withCString("Sine Tone 660"), OSNoRetain);
	auto data_source_2 = OSSharedPtr(OSString::withCString("Loopback"), OSNoRetain);
	ivars->m_data_sources[0] = { 440, data_source_0 };
	ivars->m_data_sources[1] = { 660, data_source_1 };
	ivars->m_data_sources[2] = { 0, data_source_2 };

	// Set up stream formats and other stream-related properties.
	/// - Tag: CreateStreamFormats
	double sample_rates[] = {kSampleRate_1, kSampleRate_2};
	SetAvailableSampleRates(sample_rates, 2);
	SetSampleRate(kSampleRate_1);
	const auto channels_per_frame = 1;
	IOUserAudioChannelLabel input_channel_layout[channels_per_frame] = { IOUserAudioChannelLabel::Mono };
	IOUserAudioChannelLabel output_channel_layout[channels_per_frame] = { IOUserAudioChannelLabel::Mono };

	IOUserAudioStreamBasicDescription stream_formats[] =
	{
		{
			kSampleRate_1, IOUserAudioFormatID::LinearPCM,
			static_cast<IOUserAudioFormatFlags>(IOUserAudioFormatFlags::FormatFlagIsSignedInteger | IOUserAudioFormatFlags::FormatFlagsNativeEndian),
			static_cast<uint32_t>(sizeof(int16_t)*channels_per_frame),
			1,
			static_cast<uint32_t>(sizeof(int16_t)*channels_per_frame),
			static_cast<uint32_t>(channels_per_frame),
			16
		},
		{
			kSampleRate_2, IOUserAudioFormatID::LinearPCM,
			static_cast<IOUserAudioFormatFlags>(IOUserAudioFormatFlags::FormatFlagIsSignedInteger | IOUserAudioFormatFlags::FormatFlagsNativeEndian),
			static_cast<uint32_t>(sizeof(int16_t)*channels_per_frame),
			1,
			static_cast<uint32_t>(sizeof(int16_t)*channels_per_frame),
			static_cast<uint32_t>(channels_per_frame),
			16
		},
	};

	// Add a custom property for the audio driver.
	/// - Tag: AddCustomProperty
	custom_property = IOUserAudioCustomProperty::Create(in_driver,
														prop_addr,
														true,
														IOUserAudioCustomPropertyDataType::String,
														IOUserAudioCustomPropertyDataType::String);

	// Set the qualifier and data-value pair on the custom property.
	qualifier = OSSharedPtr(OSString::withCString(kSimpleAudioDriverCustomPropertyQualifier0), OSNoRetain);
	data = OSSharedPtr(OSString::withCString(kSimpleAudioDriverCustomPropertyDataValue0), OSNoRetain);
	custom_property->SetQualifierAndDataValue(qualifier.get(), data.get());
    
	// Set another qualifier and data-value pair on the custom property.
	qualifier = OSSharedPtr(OSString::withCString(kSimpleAudioDriverCustomPropertyQualifier1), OSNoRetain);
	data = OSSharedPtr(OSString::withCString(kSimpleAudioDriverCustomPropertyDataValue1), OSNoRetain);
	custom_property->SetQualifierAndDataValue(qualifier.get(), data.get());
	AddCustomProperty(custom_property.get());

	// Create the IOBufferMemoryDescriptor ring buffer for the input stream.
	/// - Tag: CreateRingBufferAndMemoryDescriptor
	OSSharedPtr<IOBufferMemoryDescriptor> output_io_ring_buffer;
	OSSharedPtr<IOBufferMemoryDescriptor> input_io_ring_buffer;
	const auto buffer_size_bytes = static_cast<uint32_t>(in_zero_timestamp_period * sizeof(uint16_t) * channels_per_frame);
	error = IOBufferMemoryDescriptor::Create(kIOMemoryDirectionInOut, buffer_size_bytes, 0, output_io_ring_buffer.attach());
	FailIf(error != kIOReturnSuccess, , Failure, "Failed to create output IOBufferMemoryDescriptor");

	error = IOBufferMemoryDescriptor::Create(kIOMemoryDirectionInOut, buffer_size_bytes, 0, input_io_ring_buffer.attach());
	FailIf(error != kIOReturnSuccess, , Failure, "Failed to create input IOBufferMemoryDescriptor");

	// Create an output/input stream object and pass in the I/O ring buffer memory descriptor.
	ivars->m_output_stream = IOUserAudioStream::Create(in_driver, IOUserAudioStreamDirection::Output, output_io_ring_buffer.get());
	FailIfNULL(ivars->m_output_stream.get(), error = kIOReturnNoMemory, Failure, "failed to create output stream");

	ivars->m_input_stream = IOUserAudioStream::Create(in_driver, IOUserAudioStreamDirection::Input, input_io_ring_buffer.get());
	FailIfNULL(ivars->m_input_stream.get(), error = kIOReturnNoMemory, Failure, "failed to create input stream");
	
	//	Configure stream properties: name, available formats, and current format.
	ivars->m_output_stream->SetName(output_stream_name.get());
	ivars->m_output_stream->SetAvailableStreamFormats(stream_formats, 2);
	ivars->m_stream_format = stream_formats[0];
	ivars->m_output_stream->SetCurrentStreamFormat(&ivars->m_stream_format);
	
	ivars->m_input_stream->SetName(input_stream_name.get());
	ivars->m_input_stream->SetAvailableStreamFormats(stream_formats, 2);
	ivars->m_input_stream->SetCurrentStreamFormat(&ivars->m_stream_format);
	
	// Add a stream object to the driver.
	error = AddStream(ivars->m_output_stream.get());
	FailIfError(error, , Failure, "failed to add output stream");

	error = AddStream(ivars->m_input_stream.get());
	FailIfError(error, , Failure, "failed to add input stream");

	/// - Tag: AddVolumeControlObject
	// Create the volume control object for the input stream.
	ivars->m_input_volume_control = IOUserAudioLevelControl::Create(in_driver,
																	true,
																	-6.0,
																	{-96.0, 0.0},
																	IOUserAudioObjectPropertyElementMain,
																	IOUserAudioObjectPropertyScope::Input,
																	IOUserAudioClassID::VolumeControl);
	FailIfNULL(ivars->m_input_volume_control.get(), error = kIOReturnNoMemory, Failure, "Failed to create input volume control");
	ivars->m_input_volume_control->SetName(input_volume_control_name.get());
	
	// Add the volume control to the device object.
	error = AddControl(ivars->m_input_volume_control.get());
	FailIfError(error, , Failure, "failed to add input volume level control");

	// Create the input data source selector control for controlling the sine tone frequency.
	ivars->m_input_selector_control = IOUserAudioSelectorControl::Create(in_driver,
																		 true,
																		 IOUserAudioObjectPropertyElementMain,
																		 IOUserAudioObjectPropertyScope::Input,
																		 IOUserAudioClassID::DataSourceControl);
	FailIfNULL(ivars->m_input_selector_control.get(), error = kIOReturnNoMemory, Failure, "Failed to create input data source control");
	ivars->m_input_selector_control->AddControlValueDescriptions(ivars->m_data_sources, 3);
	// Set the data source selector's current value to tone with a frequency of 440 Hz.
	ivars->m_input_selector_control->SetCurrentSelectedValues(&ivars->m_data_sources[0].m_value, 1);
	ivars->m_input_selector_control->SetName(input_data_source_control.get());

	// Add the data-source selector control to the driver.
	error = AddControl(ivars->m_input_selector_control.get());
	FailIfError(error, , Failure, "failed to add input data source control");
	
	// Configure device-related information.
	SetPreferredOutputChannelLayout(output_channel_layout, channels_per_frame);
	SetTransportType(IOUserAudioTransportType::Thunderbolt);

	SetPreferredInputChannelLayout(input_channel_layout, channels_per_frame);
	SetTransportType(IOUserAudioTransportType::Thunderbolt);

	/// - Tag: InitZtsTimer
	// Initialize the timer that stands in for a real interrupt.
	error = IOTimerDispatchSource::Create(ivars->m_work_queue.get(), &zts_timer_event_source);
	FailIfError(error, , Failure, "failed to create the ZTS timer event source");
	ivars->m_zts_timer_event_source = OSSharedPtr(zts_timer_event_source, OSNoRetain);
	
	// Create a timer action to generate timestamps.
	error = CreateActionZtsTimerOccurred(sizeof(void*), &zts_timer_occurred_action);
	FailIfError(error, , Failure, "failed to create the timer event source action");
	ivars->m_zts_timer_occurred_action = OSSharedPtr(zts_timer_occurred_action, OSNoRetain);
	ivars->m_zts_timer_event_source->SetHandler(ivars->m_zts_timer_occurred_action.get());
	
	/// - Tag: CreateRealTimeAudioCallback
	io_operation = ^kern_return_t(IOUserAudioObjectID in_device,
								  IOUserAudioIOOperation in_io_operation,
								  uint32_t in_io_buffer_frame_size,
								  uint64_t in_sample_time,
								  uint64_t in_host_time)
	{
		if (in_io_operation == IOUserAudioIOOperationWriteEnd)
		{
			// no-op, Host has written data to the output buffer
		}
		else if (in_io_operation == IOUserAudioIOOperationBeginRead)
		{
			// Either generate tone, or loopback data from the output buffer.
			IOUserAudioSelectorValue tone_selector_value = 0;
			ivars->m_input_selector_control->GetCurrentSelectedValues(&tone_selector_value, 1);

			// Loopback output to input buffer.
			if (tone_selector_value == 0)
			{
				if ((ivars->m_input_memory_map.get() == nullptr) || (ivars->m_output_memory_map.get() == nullptr))
				{
					return kIOReturnNoMemory;
				}
				
				auto input_volume_level = ivars->m_input_volume_control->GetScalarValue();

				const auto& format = ivars->m_stream_format;
				auto output_buffer_length = ivars->m_output_memory_map->GetLength() / sizeof(int16_t);
				auto output_buffer = reinterpret_cast<int16_t*>(ivars->m_output_memory_map->GetAddress() + ivars->m_output_memory_map->GetOffset());
				
				auto input_buffer_length = ivars->m_input_memory_map->GetLength() / sizeof(int16_t);
				auto input_buffer = reinterpret_cast<int16_t*>(ivars->m_input_memory_map->GetAddress() + ivars->m_input_memory_map->GetOffset());

				for (auto i = 0; i < (format.mChannelsPerFrame * in_io_buffer_frame_size); i++)
				{
					auto input_buffer_index = (format.mChannelsPerFrame * in_sample_time + i) % input_buffer_length;
					auto output_buffer_index = (format.mChannelsPerFrame * in_sample_time + i) % output_buffer_length;
					input_buffer[input_buffer_index] = input_volume_level * output_buffer[output_buffer_index];
				}
			}
			else
			{
				// Generate tone using the selector control value as the tone frequency.
				double frequency = static_cast<double>(tone_selector_value);
				GenerateToneForInput(frequency, in_sample_time, in_io_buffer_frame_size);
			}
		}
		
		return kIOReturnSuccess;
	};

	/// - Tag: SetRealTimeAudioCallback
	this->SetIOOperationHandler(io_operation);
    
	return true;
	
Failure:
	ivars->m_driver.reset();
	ivars->m_output_stream.reset();
	ivars->m_output_memory_map.reset();
	ivars->m_input_stream.reset();
	ivars->m_input_memory_map.reset();
	ivars->m_input_volume_control.reset();
	ivars->m_zts_timer_event_source.reset();
	ivars->m_zts_timer_occurred_action.reset();
	return false;
}

void SimpleAudioDevice::free()
{
	if (ivars != nullptr)
	{
		ivars->m_driver.reset();
		ivars->m_output_stream.reset();
		ivars->m_output_memory_map.reset();
		ivars->m_input_stream.reset();
		ivars->m_input_memory_map.reset();
		ivars->m_input_volume_control.reset();
		ivars->m_input_selector_control.reset();
		ivars->m_zts_timer_event_source.reset();
		ivars->m_zts_timer_occurred_action.reset();
		ivars->m_work_queue.reset();
	}
	IOSafeDeleteNULL(ivars, SimpleAudioDevice_IVars, 1);
	super::free();
}

/// - Tag: StartIOImpl
kern_return_t SimpleAudioDevice::StartIO(IOUserAudioStartStopFlags in_flags)
{
	DebugMsg("Start I/O: device %u", GetObjectID());
	
	__block kern_return_t error = kIOReturnSuccess;
	__block OSSharedPtr<IOMemoryDescriptor> input_iomd;
	__block OSSharedPtr<IOMemoryDescriptor> output_iomd;

	ivars->m_work_queue->DispatchSync(^(){
		//	Tell IOUserAudioObject base class to start I/O for the device.
		error = super::StartIO(in_flags);
		FailIfError(error, , Failure, "Failed to start I/O");
		
		output_iomd = ivars->m_output_stream->GetIOMemoryDescriptor();
		FailIfNULL(output_iomd.get(), error = kIOReturnNoMemory, Failure, "Failed to get output stream IOMemoryDescriptor");
		error = output_iomd->CreateMapping(0, 0, 0, 0, 0, ivars->m_output_memory_map.attach());
		FailIf(error != kIOReturnSuccess, , Failure, "Failed to create memory map from output stream IOMemoryDescriptor");
		
		input_iomd = ivars->m_input_stream->GetIOMemoryDescriptor();
		FailIfNULL(input_iomd.get(), error = kIOReturnNoMemory, Failure, "Failed to get input stream IOMemoryDescriptor");
		error = input_iomd->CreateMapping(0, 0, 0, 0, 0, ivars->m_input_memory_map.attach());
		FailIf(error != kIOReturnSuccess, , Failure, "Failed to create memory map from input stream IOMemoryDescriptor");

		// Start the timers to send timestamps and generate sine tone on the stream I/O buffer.
		StartTimers();
		return;
		
	Failure:
		super::StopIO(in_flags);
		ivars->m_output_memory_map.reset();
		ivars->m_input_memory_map.reset();
		return;
	});

	return error;
}

kern_return_t SimpleAudioDevice::StopIO(IOUserAudioStartStopFlags in_flags)
{
	DebugMsg("Stop IO: device %u", GetObjectID());

	// Tell the IOUserAudioObject base class to stop I/O for the device.
	__block kern_return_t error;
	
	ivars->m_work_queue->DispatchSync(^(){
		// Stop the timers for timestamps and sine tone generator.
		StopTimers();

		error = super::StopIO(in_flags);
	});


	if (error != kIOReturnSuccess)
   {
	   DebugMsg("Failed to stop IO, error %d", error);
   }

	return error;
}

/// - Tag: PerformDeviceConfigurationChange
kern_return_t SimpleAudioDevice::PerformDeviceConfigurationChange(uint64_t change_action, OSObject* in_change_info)
{
	DebugMsg("change action %llu", change_action);
	kern_return_t ret = kIOReturnSuccess;
	switch (change_action) {
			// Add custom config change handlers.
		case k_custom_config_change_action:
		{
			if (in_change_info)
			{
				auto change_info_string = OSDynamicCast(OSString, in_change_info);
				DebugMsg("%s", change_info_string->getCStringNoCopy());
			}
			
			// Toggle the sample rate of the device.
			double rate_to_set = static_cast<uint64_t>(GetSampleRate()) != static_cast<uint64_t>(kSampleRate_1) ? kSampleRate_1 : kSampleRate_2;
			ret = SetSampleRate(rate_to_set);
			if (ret == kIOReturnSuccess)
			{
				// Update the stream formats with the new rate.
				ret = ivars->m_input_stream->DeviceSampleRateChanged(rate_to_set);
				ret = ivars->m_output_stream->DeviceSampleRateChanged(rate_to_set);
			}
		}
			break;
			
		default:
			ret = super::PerformDeviceConfigurationChange(change_action, in_change_info);
			break;
	}
	
	// Update the cached format.
	ivars->m_stream_format = ivars->m_input_stream->GetCurrentStreamFormat();
	
	return ret;
}

kern_return_t SimpleAudioDevice::AbortDeviceConfigurationChange(uint64_t change_action, OSObject* in_change_info)
{
	// Handle aborted configuration changes as necessary.
	return super::AbortDeviceConfigurationChange(change_action, in_change_info);
}

kern_return_t SimpleAudioDevice::HandleChangeSampleRate(double in_sample_rate)
{
	// This method runs when the HAL changes the sample rate of the device.
	// Add custom operations here to configure hardware and return success
	// to continue with the sample rate change.
	return SetSampleRate(in_sample_rate);
}

inline int16_t SimpleAudioDevice::FloatToInt16(float in_sample)
{
	if (in_sample > 1.0f)
	{
		in_sample = 1.0f;
	}
	else if (in_sample < -1.0f)
	{
		in_sample = -1.0f;
	}
	return static_cast<int16_t>(in_sample * 0x7fff);
}

kern_return_t SimpleAudioDevice::StartTimers()
{
	kern_return_t error = kIOReturnSuccess;
	
	UpdateTimers();
	
	if(ivars->m_zts_timer_event_source.get() != nullptr)
	{
		/// - Tag: StartTimers
		// Clear the device's timestamps.
		UpdateCurrentZeroTimestamp(0, 0);
		auto current_time = mach_absolute_time();

		// Start the timer. The first timestamp occurs when the timer goes off.
		ivars->m_zts_timer_event_source->WakeAtTime(kIOTimerClockMachAbsoluteTime, current_time + ivars->m_zts_host_ticks_per_buffer, 0);
		ivars->m_zts_timer_event_source->SetEnable(true);
	}
	else
	{
		error = kIOReturnNoResources;
	}
	
	return error;
}

void	SimpleAudioDevice::StopTimers()
{
	if(ivars->m_zts_timer_event_source.get() != nullptr)
	{
		ivars->m_zts_timer_event_source->SetEnable(false);
	}
}

void	SimpleAudioDevice::UpdateTimers()
{
	struct mach_timebase_info timebase_info;
	mach_timebase_info(&timebase_info);
	
	double sample_rate = ivars->m_stream_format.mSampleRate;
	double host_ticks_per_buffer = static_cast<double>(GetZeroTimestampPeriod() * NSEC_PER_SEC) / sample_rate;
	host_ticks_per_buffer = (host_ticks_per_buffer * static_cast<double>(timebase_info.denom)) / static_cast<double>(timebase_info.numer);
	ivars->m_zts_host_ticks_per_buffer = static_cast<uint64_t>(host_ticks_per_buffer);
}

/// - Tag: ZtsTimerOccurred
void	SimpleAudioDevice::ZtsTimerOccurred_Impl(OSAction* action, uint64_t time)
{
	// Get the current time.
	auto current_time = time;
	
	// Increment the timestamps...
	uint64_t current_sample_time = 0;
	uint64_t current_host_time = 0;
	GetCurrentZeroTimestamp(&current_sample_time, &current_host_time);
	
	auto host_ticks_per_buffer = ivars->m_zts_host_ticks_per_buffer;
	
	if(current_host_time != 0)
	{
		current_sample_time += GetZeroTimestampPeriod();
		current_host_time += host_ticks_per_buffer;
	}
	else
	{
		// ...but not if it's the first one.
		current_sample_time = 0;
		current_host_time = current_time;
	}
	
	// Update the device with the current timestamp.
	UpdateCurrentZeroTimestamp(current_sample_time, current_host_time);
	
	// Set the timer to go off in one buffer.
	ivars->m_zts_timer_event_source->WakeAtTime(kIOTimerClockMachAbsoluteTime,
												current_host_time + host_ticks_per_buffer, 0);
}

/// - Tag: GenerateToneForInput
void SimpleAudioDevice::GenerateToneForInput(double in_tone_freq, size_t in_sample_time, size_t in_frame_size)
{
	// Fill out the input buffer with a sine tone.
	if (ivars->m_input_memory_map)
	{
		// Get the pointer to the I/O buffer and use stream format information
		// to get the buffer length.
		const auto& format = ivars->m_stream_format;
		auto buffer_length = ivars->m_input_memory_map->GetLength() / (format.mBytesPerFrame / format.mChannelsPerFrame);
		auto num_samples = in_frame_size;
		auto buffer = reinterpret_cast<int16_t*>(ivars->m_input_memory_map->GetAddress() + ivars->m_input_memory_map->GetOffset());

		// Get the volume control dB value to apply gain to the tone.
		auto input_volume_level = ivars->m_input_volume_control->GetScalarValue();
		
		for(size_t i = 0; i < num_samples; i++)
		{
			float float_value = input_volume_level * sin(2.0 * M_PI * in_tone_freq * static_cast<double>(ivars->m_tone_sample_index) / format.mSampleRate);
			int16_t integer_value = FloatToInt16(float_value);
			for (auto channel_index = 0; channel_index < format.mChannelsPerFrame; channel_index++)
			{
				auto buffer_index = (format.mChannelsPerFrame * (in_sample_time + i) + channel_index) % buffer_length;
				buffer[buffer_index] = integer_value;
			}
			ivars->m_tone_sample_index += 1;
		}
	}
}

kern_return_t SimpleAudioDevice::ToggleDataSource()
{
	__block kern_return_t ret = kIOReturnSuccess;
	GetWorkQueue()->DispatchSync(^(){
		IOUserAudioSelectorValue current_data_source_value;
		ivars->m_input_selector_control->GetCurrentSelectedValues(&current_data_source_value, 1);
		
		
		IOUserAudioSelectorValue data_source_value_to_set = current_data_source_value;
		if (current_data_source_value == ivars->m_data_sources[0].m_value)
		{
			data_source_value_to_set = ivars->m_data_sources[1].m_value;
		}
		else if (current_data_source_value == ivars->m_data_sources[1].m_value)
		{
			data_source_value_to_set = ivars->m_data_sources[2].m_value;
		}
		else
		{
			data_source_value_to_set = ivars->m_data_sources[0].m_value;
		}
		ret = ivars->m_input_selector_control->SetCurrentSelectedValues(&data_source_value_to_set, 1);
	});
	return ret;
}
