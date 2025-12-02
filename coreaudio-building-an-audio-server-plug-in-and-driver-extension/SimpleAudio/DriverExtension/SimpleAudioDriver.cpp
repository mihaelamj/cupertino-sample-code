/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A minimal user-space driver.
*/

/*==================================================================================================
	SimpleAudioDriver.cpp
==================================================================================================*/

//	Self Include
#include "SimpleAudioDriver.h"

//	Standard Library Includes
#include <cstdio>
#include <cstdlib>

//	System Includes
#include <os/log.h>

//	Local Includes
#include "SimpleAudioDriverTypes.h"

//==================================================================================================

constexpr inline const char* safe_strrchr(const char* in_string, int in_char, size_t in_max_length) noexcept
{
	const char* answer = nullptr;
	for (size_t index = 0; (*in_string != 0) && (index < in_max_length); ++in_string, ++index)
	{
		if (*in_string == in_char)
		{
			answer = in_string;
		}
	}
	return answer;
}

constexpr inline const char* filename_only(const char* in_path, size_t in_max_length = 4096) noexcept
{
	//	The biggest bummer here is that we can't know the length of the path ahead of time where
	//	this function is useful. We substitue 4k here, which is probalby overkill.
	const char* answer = safe_strrchr(in_path, '/', in_max_length);
	return (answer != nullptr) ? answer + 1 : in_path;
}

#define	DebugMsg(inFormat, ...)	os_log(OS_LOG_DEFAULT, "%s:%d %s" inFormat "\n", filename_only(__FILE__), __LINE__, __func__, ## __VA_ARGS__)

#define	FailIf(inCondition, inAction, inHandler, inMessage)									\
			{																				\
				bool __failed = (inCondition);												\
				if(__failed)																\
				{																			\
					DebugMsg(inMessage);													\
					{ inAction; }															\
					goto inHandler;															\
				}																			\
			}

#define	FailIfError(inError, inAction, inHandler, inMessage)								\
			{																				\
				IOReturn __Err = (inError);													\
				if(__Err != 0)																\
				{																			\
					DebugMsg(inMessage ", Error: %d (0x%X)", __Err, (unsigned int)__Err);	\
					{ inAction; }															\
					goto inHandler;															\
				}																			\
			}

#define	FailIfNULL(inPointer, inAction, inHandler, inMessage)								\
			if((inPointer) == NULL)															\
			{																				\
				DebugMsg(inMessage);														\
				{ inAction; }																\
				goto inHandler;																\
			}


static kern_return_t	AllocateBufferDescriptor(uint64_t in_options, uint64_t in_capacity, uint64_t in_alignment, IOBufferMemoryDescriptor** out_descriptor, void** out_buffer) noexcept
{
	kern_return_t error = kIOReturnSuccess;
	IOBufferMemoryDescriptor* descriptor = nullptr;
	IOAddressSegment segment = {0, 0};

	error = IOBufferMemoryDescriptor::Create(in_options, in_capacity, in_alignment, &descriptor);
	FailIfError(error,, Failure, "failed to create the buffer memory descriptor");
	segment = {0, 0};
	error = descriptor->GetAddressRange(&segment);
	FailIfError(error,, Failure, "failed to get the buffer from the descriptor");

	*out_descriptor = descriptor;
	*out_buffer = reinterpret_cast<void*>(segment.address);

	return kIOReturnSuccess;

Failure:
	OSSafeReleaseNULL(descriptor);
	return error;
}

struct SimpleAudioDriver_IVars
{
	IODispatchQueue*			m_work_queue;

	IOBufferMemoryDescriptor*	m_status_descriptor;
	SimpleAudioDriverStatus*	m_status_buffer;
	IOBufferMemoryDescriptor*	m_input_descriptor;
	int16_t*					m_input_buffer;
	IOBufferMemoryDescriptor*	m_output_descriptor;
	int16_t*					m_output_buffer;
	uint64_t					m_io_buffer_frame_size;

	IOTimerDispatchSource*		m_timer_event_source;
	OSAction*					m_timer_occurred_action;
	bool						m_is_running;
	uint64_t					m_sample_rate;
	uint64_t					m_host_ticks_per_buffer;

	uint32_t					m_master_input_volume;
	uint32_t					m_master_output_volume;
};

bool	SimpleAudioDriver::init()
{
	DebugMsg("");

	auto answer = super::init();
	if (!answer)
	{
		return false;
	}
	ivars = IONewZero(SimpleAudioDriver_IVars, 1);
	if (ivars == nullptr)
	{
		return false;
	}
	return true;
}

void	SimpleAudioDriver::free()
{
	DebugMsg("");

	if (ivars != nullptr)
	{
		OSSafeReleaseNULL(ivars->m_work_queue);
		OSSafeReleaseNULL(ivars->m_status_descriptor);
		OSSafeReleaseNULL(ivars->m_input_descriptor);
		OSSafeReleaseNULL(ivars->m_output_descriptor);
		OSSafeReleaseNULL(ivars->m_timer_event_source);
		OSSafeReleaseNULL(ivars->m_timer_occurred_action);
	}
	IOSafeDeleteNULL(ivars, SimpleAudioDriver_IVars, 1);
   super::free();
}

kern_return_t	SimpleAudioDriver::Start_Impl(IOService* in_provider)
{
	DebugMsg("provider: %p", in_provider);

	//	Local Variables
	OSDictionary* properties = nullptr;
	kern_return_t error = kIOReturnSuccess;

	error = Start(in_provider, SUPERDISPATCH);
    FailIfError(error,,Failure, "super::Start: failed");

	//	get the service's default dispatch queue to use to run the timer
	error = CopyDispatchQueue("Default", &ivars->m_work_queue);
    FailIfError(error,,Failure, "failed to create the work queue");

    //	make a dictionary to hold the new registry properties
    properties = OSDictionaryCreate();
    FailIf(!properties, error = kIOReturnNoSpace, Failure, "failed to allocate registry properties");

	//	initialize the stuff tracked by the IORegistry
	ivars->m_sample_rate = 48000;
	OSDictionarySetUInt64Value(properties, kSimpleAudioDriver_RegistryKey_SampleRate, ivars->m_sample_rate);

	ivars->m_io_buffer_frame_size = 16384;
	OSDictionarySetUInt64Value(properties, kSimpleAudioDriver_RegistryKey_RingBufferFrameSize, ivars->m_io_buffer_frame_size);

	OSDictionarySetStringValue(properties, kSimpleAudioDriver_RegistryKey_DeviceUID, "SimpleAudioDevice-0");

	SetProperties(properties);
	OSSafeReleaseNULL(properties);

	//	allocate the IO buffers

	//	The status buffer holds the zero time stamp when IO is running
	error = AllocateBufferDescriptor(kIOMemoryDirectionOut, sizeof(SimpleAudioDriverStatus), 0, &ivars->m_status_descriptor, reinterpret_cast<void**>(&ivars->m_status_buffer));
	FailIfError(error,, Failure, "failed to allocate the status buffer");

	//	These are the ring buffers for transmitting the audio data
	//	Note that for this driver the samples are always 16 bit stereo
	error = AllocateBufferDescriptor(kIOMemoryDirectionOut, ivars->m_io_buffer_frame_size * 2 * 2, 0, &ivars->m_input_descriptor, reinterpret_cast<void**>(&ivars->m_input_buffer));
	FailIfError(error,, Failure, "failed to allocate the input buffer");

	error = AllocateBufferDescriptor(kIOMemoryDirectionOut, ivars->m_io_buffer_frame_size * 2 * 2, 0, &ivars->m_output_descriptor, reinterpret_cast<void**>(&ivars->m_output_buffer));
	FailIfError(error,, Failure, "failed to allocate the output buffer");

	//	initialize the timer that stands in for a real interrupt
    error = IOTimerDispatchSource::Create(ivars->m_work_queue, &ivars->m_timer_event_source);
    FailIfError(error,,Failure, "failed to create the timer event source");

	error = CreateActionTimerOccurred(sizeof(void*), &ivars->m_timer_occurred_action);
    FailIfError(error,,Failure, "failed to create the timer event source action");
	ivars->m_timer_event_source->SetHandler(ivars->m_timer_occurred_action);

	//	calculate how many ticks are in each buffer
	UpdateTimer();

	//	initialize the controls
	ivars->m_master_input_volume = kSimpleAudioDriver_Control_MaxRawVolumeValue;
	ivars->m_master_output_volume = kSimpleAudioDriver_Control_MaxRawVolumeValue;

	//	register the service
	error = RegisterService();
	FailIfError(error,, Failure, "registering the service failed");

    return kIOReturnSuccess;

Failure:
	OSSafeReleaseNULL(ivars->m_status_descriptor);
	OSSafeReleaseNULL(ivars->m_input_descriptor);
	OSSafeReleaseNULL(ivars->m_output_descriptor);
	OSSafeReleaseNULL(ivars->m_work_queue);
	OSSafeReleaseNULL(ivars->m_timer_event_source);
	OSSafeReleaseNULL(ivars->m_timer_occurred_action);
	return error;
}

kern_return_t	SimpleAudioDriver::Stop_Impl(IOService* in_provider)
{
	DebugMsg("provider: %p", in_provider);

	StopHardware();
	__block _Atomic uint32_t count = 2;
	void (^finalize)(void) =
	^{
		if (__c11_atomic_fetch_sub(&count, 1U, __ATOMIC_RELAXED) < 2)
		{
			OSSafeReleaseNULL(ivars->m_status_descriptor);
			OSSafeReleaseNULL(ivars->m_input_descriptor);
			OSSafeReleaseNULL(ivars->m_output_descriptor);
			OSSafeReleaseNULL(ivars->m_work_queue);
			OSSafeReleaseNULL(ivars->m_timer_event_source);
			Stop(in_provider, SUPERDISPATCH);
		}
	};
	ivars->m_timer_event_source->Cancel(finalize);
	ivars->m_work_queue->Cancel(finalize);
	return kIOReturnSuccess;
}

kern_return_t	SimpleAudioDriver::NewUserClient_Impl(uint32_t in_type, IOUserClient** out_user_client)
{
	DebugMsg("type: %u out_user-client: %p", in_type, out_user_client);

	kern_return_t error = kIOReturnSuccess;
	IOService* service = nullptr;
	IOUserClient* user_client = nullptr;

	error = Create(this, "SimpleAudioDriverUserClientProperties", &service);
	FailIfError(error,, Failure, "failed to Create the user-client");

	user_client = OSDynamicCast(IOUserClient, service);
	FailIfNULL(user_client, error = kIOReturnInvalid, Failure, "created object isn't an IOUserClient");
	*out_user_client = user_client;

    return kIOReturnSuccess;

Failure:
	OSSafeReleaseNULL(service);
    return error;
}

IOMemoryDescriptor*	SimpleAudioDriver::CopyBuffer(uint64_t in_buffer_type)
{
	DebugMsg("type: %llu", in_buffer_type);

	switch (in_buffer_type)
	{
		case kSimpleAudioDriver_Buffer_Status:
			return ivars->m_status_descriptor;

		case kSimpleAudioDriver_Buffer_Input:
			return ivars->m_input_descriptor;

		case kSimpleAudioDriver_Buffer_Output:
			return ivars->m_output_descriptor;
	};
	return nullptr;
}

kern_return_t	SimpleAudioDriver::StartHardware()
{
	DebugMsg("");

	if (ivars->m_work_queue == nullptr)
	{
		return kIOReturnNotReady;
	}

	if ((ivars->m_input_buffer == nullptr) || (ivars->m_output_buffer == nullptr))
	{
		return kIOReturnNotReady;
	}

	__block kern_return_t error = kIOReturnSuccess;
	ivars->m_work_queue->DispatchSync(
	^{
		if (ivars->m_is_running)
		{
			return;
		}

		//	clear the buffers
		bzero(ivars->m_input_buffer, ivars->m_io_buffer_frame_size * 4);
		bzero(ivars->m_output_buffer, ivars->m_io_buffer_frame_size * 4);

		//	start the timer
		error = StartTimer();
		if (error != kIOReturnSuccess)
		{
			return;
		}

		ivars->m_is_running = true;
	});

	return error;
}

void	SimpleAudioDriver::StopHardware()
{
	DebugMsg("");

	if (ivars->m_work_queue == nullptr)
	{
		return;
	}

	ivars->m_work_queue->DispatchSync(
	^{
		if (!ivars->m_is_running)
		{
			return;
		}

		//	stop the timer
		StopTimer();
		ivars->m_is_running = false;
	});
}

kern_return_t	SimpleAudioDriver::GetSampleRate(uint64_t& out_sample_rate)
{
	DebugMsg("");

	if (ivars->m_work_queue == nullptr)
	{
		return kIOReturnNotReady;
	}

	ivars->m_work_queue->DispatchSync(
	^{
		out_sample_rate = ivars->m_sample_rate;
	});

	return kIOReturnSuccess;
}

kern_return_t	SimpleAudioDriver::SetSampleRate(uint64_t in_new_sample_rate)
{
	DebugMsg("new rate: %llu", in_new_sample_rate);

	if (ivars->m_work_queue == nullptr)
	{
		return kIOReturnNotReady;
	}

	if ((in_new_sample_rate != 44100) && (in_new_sample_rate != 48000))
	{
		return kIOReturnUnsupported;
	}

	__block kern_return_t error = kIOReturnSuccess;
	ivars->m_work_queue->DispatchSync(
	^{
		if (ivars->m_is_running)
		{
			error = kIOReturnNotPermitted;
			return;
		}

		if (ivars->m_sample_rate == in_new_sample_rate)
		{
			return;
		}

		auto properties = OSDictionaryCreate();
		if (properties == nullptr)
		{
			error = kIOReturnNoMemory;
			return;
		}
		OSDictionarySetUInt64Value(properties, kSimpleAudioDriver_RegistryKey_SampleRate, in_new_sample_rate);
		OSDictionarySetUInt64Value(properties, kSimpleAudioDriver_RegistryKey_RingBufferFrameSize, ivars->m_io_buffer_frame_size);
		OSDictionarySetStringValue(properties, kSimpleAudioDriver_RegistryKey_DeviceUID, "SimpleAudioDevice-0");
		SetProperties(properties);
		OSSafeReleaseNULL(properties);
		
		ivars->m_sample_rate = in_new_sample_rate;
		UpdateTimer();
	});

	return error;
}

kern_return_t SimpleAudioDriver::StartTimer()
{
	DebugMsg("");

	kern_return_t error = kIOReturnSuccess;

	if((ivars->m_status_buffer != nullptr) && (ivars->m_timer_event_source != nullptr))
	{
		//	clear the status buffer
		ivars->m_status_buffer->mSampleTime = 0;
		ivars->m_status_buffer->mHostTime = 0;

		//	start the timer, the first time stamp will be taken when it goes off
		ivars->m_timer_event_source->WakeAtTime(kIOTimerClockMachAbsoluteTime, mach_absolute_time() + ivars->m_host_ticks_per_buffer, 0);
		ivars->m_timer_event_source->SetEnable(true);
	}
	else
	{
		error = kIOReturnNoResources;
	}

	return error;
}

void	SimpleAudioDriver::StopTimer()
{
	DebugMsg("");

	if(ivars->m_timer_event_source != nullptr)
	{
		ivars->m_timer_event_source->SetEnable(false);
	}
}

void	SimpleAudioDriver::UpdateTimer()
{
	DebugMsg("");

	struct mach_timebase_info timebase_info;
	mach_timebase_info(&timebase_info);
	ivars->m_host_ticks_per_buffer = (ivars->m_io_buffer_frame_size * 1000000000ULL) / ivars->m_sample_rate;
	ivars->m_host_ticks_per_buffer = (ivars->m_host_ticks_per_buffer * timebase_info.denom) / timebase_info.numer;
}

void	SimpleAudioDriver::TimerOccurred_Impl(OSAction* action, uint64_t time)
{
	DebugMsg("action: %p time: %llu", action, time);

	//	validate the engine
	if(ivars->m_status_buffer == nullptr)
	{
		return;
	}

	//	get the current time
	auto current_time = mach_absolute_time();

	//	increment the time stamps
	if(ivars->m_status_buffer->mHostTime != 0)
	{
		ivars->m_status_buffer->mSampleTime += ivars->m_io_buffer_frame_size;
		ivars->m_status_buffer->mHostTime += ivars->m_host_ticks_per_buffer;
	}
	else
	{
		//	but not if it's the first one
		ivars->m_status_buffer->mSampleTime = 0;
		ivars->m_status_buffer->mHostTime = current_time;
	}

	//	set the timer to go off in one buffer
	ivars->m_timer_event_source->WakeAtTime(kIOTimerClockMachAbsoluteTime, ivars->m_status_buffer->mHostTime + ivars->m_host_ticks_per_buffer, 0);
}

kern_return_t	SimpleAudioDriver::GetVolume(uint32_t in_volume_id, uint32_t& out_volume)
{
	DebugMsg("");

	if (ivars->m_work_queue == nullptr)
	{
		return kIOReturnNotReady;
	}

	if ((in_volume_id != kSimpleAudioDriver_Control_MasterInputVolume) && (in_volume_id != kSimpleAudioDriver_Control_MasterOutputVolume))
	{
		return kIOReturnNotFound;
	}

	ivars->m_work_queue->DispatchSync(
	^{
		if (in_volume_id == kSimpleAudioDriver_Control_MasterInputVolume)
		{
			out_volume = ivars->m_master_input_volume;
		}
		else if (in_volume_id == kSimpleAudioDriver_Control_MasterOutputVolume)
		{
			out_volume = ivars->m_master_output_volume;
		}
	});

	return kIOReturnSuccess;
}

kern_return_t	SimpleAudioDriver::SetVolume(uint32_t in_volume_id, uint32_t in_new_volume)
{
	DebugMsg("");

	if (ivars->m_work_queue == nullptr)
	{
		return kIOReturnNotReady;
	}

	if ((in_volume_id != kSimpleAudioDriver_Control_MasterInputVolume) && (in_volume_id != kSimpleAudioDriver_Control_MasterOutputVolume))
	{
		return kIOReturnNotFound;
	}

	if(in_new_volume > kSimpleAudioDriver_Control_MaxRawVolumeValue)
	{
		in_new_volume = kSimpleAudioDriver_Control_MaxRawVolumeValue;
	}

	ivars->m_work_queue->DispatchSync(
	^{
		if (in_volume_id == kSimpleAudioDriver_Control_MasterInputVolume)
		{
			ivars->m_master_input_volume = in_new_volume;
		}
		else if (in_volume_id == kSimpleAudioDriver_Control_MasterOutputVolume)
		{
			ivars->m_master_output_volume = in_new_volume;
		}
	});

	return kIOReturnSuccess;
}
