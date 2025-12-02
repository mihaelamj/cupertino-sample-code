/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A minimal user-space driver.
*/

/*==================================================================================================
	SimpleAudioDriverUserClient.cpp
==================================================================================================*/

//	Self Include
#include "SimpleAudioDriverUserClient.h"

//	System Includes
#include <DriverKit/DriverKit.h>

//	Local Includes
#include "SimpleAudioDriver.h"
#include "SimpleAudioDriverTypes.h"

struct SimpleAudioDriverUserClient_IVars
{
	SimpleAudioDriver*	m_provider = nullptr;
};

bool	SimpleAudioDriverUserClient::init()
{
	auto theAnswer = super::init();
	if (!theAnswer)
	{
		return false;
	}
	ivars = IONewZero(SimpleAudioDriverUserClient_IVars, 1);
	if (ivars == nullptr)
	{
		return false;
	}
	return true;
}

void	SimpleAudioDriverUserClient::free()
{
	if (ivars != nullptr)
	{
		OSSafeReleaseNULL(ivars->m_provider);
	}
	IOSafeDeleteNULL(ivars, SimpleAudioDriverUserClient_IVars, 1);
    super::free();
}

kern_return_t	SimpleAudioDriverUserClient::Start_Impl(IOService* in_provider)
{
	auto theSimpleAudioDriver = OSDynamicCast(SimpleAudioDriver, in_provider);
	if (theSimpleAudioDriver == nullptr)
	{
		return kIOReturnBadArgument;
	}

    auto theAnswer = Start(in_provider, SUPERDISPATCH);
    if (theAnswer != kIOReturnSuccess)
    {
    	return theAnswer;
    }

	theSimpleAudioDriver->retain();
	ivars->m_provider = theSimpleAudioDriver;

    return kIOReturnSuccess;
}

kern_return_t	SimpleAudioDriverUserClient::Stop_Impl(IOService* in_provider)
{
	OSSafeReleaseNULL(ivars->m_provider);
	auto theAnswer = Stop(in_provider, SUPERDISPATCH);
	return theAnswer;
}

kern_return_t	SimpleAudioDriverUserClient::CopyClientMemoryForType_Impl(uint64_t in_type, uint64_t* out_options, IOMemoryDescriptor** out_descriptor)
{
	if (ivars == nullptr)
	{
		return kIOReturnNoResources;
	}
	if (ivars->m_provider == nullptr)
	{
		return kIOReturnNotAttached;
	}
	auto descriptor = ivars->m_provider->CopyBuffer(in_type);
	if (descriptor == nullptr)
	{
		return kIOReturnNoMemory;
	}
	descriptor->retain();
	*out_descriptor = descriptor;
	*out_options = 0;
	return kIOReturnSuccess;
}

kern_return_t	SimpleAudioDriverUserClient::ExternalMethod(uint64_t in_selector, IOUserClientMethodArguments* in_arguments, const IOUserClientMethodDispatch* in_dispatch, OSObject* in_target, void* in_reference)
{
	if (ivars == nullptr)
	{
		return kIOReturnNoResources;
	}
	if (ivars->m_provider == nullptr)
	{
		return kIOReturnNotAttached;
	}
	switch(in_selector)
	{
		case kSimpleAudioDriver_Method_Open:
		{
			return kIOReturnSuccess;
		}

		case kSimpleAudioDriver_Method_Close:
		{
			ivars->m_provider->StopHardware();
			return kIOReturnSuccess;
		}

		case kSimpleAudioDriver_Method_StartHardware:
		{
			return ivars->m_provider->StartHardware();
		}

		case kSimpleAudioDriver_Method_StopHardware:
		{
			ivars->m_provider->StopHardware();
			return kIOReturnSuccess;
		}

		case kSimpleAudioDriver_Method_SetSampleRate:
		{
			if (in_arguments->scalarInputCount != 1)
			{
				return kIOReturnBadArgument;
			}
			return ivars->m_provider->SetSampleRate(in_arguments->scalarInput[0]);
		}

		case kSimpleAudioDriver_Method_GetControlValue:
		{
			if ((in_arguments->scalarInputCount != 1) || (in_arguments->scalarOutputCount != 1))
			{
				return kIOReturnBadArgument;
			}
			auto control_id = static_cast<uint32_t>(in_arguments->scalarInput[0]);
			uint32_t control_value = 0;
			auto error = ivars->m_provider->GetVolume(control_id, control_value);
			if (error != kIOReturnSuccess)
			{
				return error;
			}
			in_arguments->scalarOutput[0] = control_value;
			return kIOReturnSuccess;
		}

		case kSimpleAudioDriver_Method_SetControlValue:
		{
			if (in_arguments->scalarInputCount != 2)
			{
				return kIOReturnBadArgument;
			}
			auto control_id = static_cast<uint32_t>(in_arguments->scalarInput[0]);
			auto control_value = static_cast<uint32_t>(in_arguments->scalarInput[1]);
			return ivars->m_provider->SetVolume(control_id, control_value);
		}

		default:
			return super::ExternalMethod(in_selector, in_arguments, in_dispatch, in_target, in_reference);
	};
}
