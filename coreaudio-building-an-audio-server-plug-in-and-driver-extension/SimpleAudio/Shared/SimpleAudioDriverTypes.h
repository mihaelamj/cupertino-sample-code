/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A minimal user-space driver.
*/

/*==================================================================================================
	SimpleAudioDriverTypes.h
==================================================================================================*/
#if !defined(__SimpleAudioDriverTypes_h__)
#define __SimpleAudioDriverTypes_h__

#include <cstdint>

//==================================================================================================
//	Constants
//==================================================================================================

//	the class name for the part of the driver for which a matching notificaiton will be created
#define kSimpleAudioDriverClassName	"SimpleAudioDriver"

//	IORegistry keys that have the basic info about the driver
#define kSimpleAudioDriver_RegistryKey_SampleRate			"sample rate"
#define kSimpleAudioDriver_RegistryKey_RingBufferFrameSize	"buffer frame size"
#define kSimpleAudioDriver_RegistryKey_DeviceUID			"device UID"

//	memory types
enum
{
	kSimpleAudioDriver_Buffer_Status,
	kSimpleAudioDriver_Buffer_Input,
	kSimpleAudioDriver_Buffer_Output
};

//	user client method selectors
enum
{
	kSimpleAudioDriver_Method_Open,				//	No arguments
	kSimpleAudioDriver_Method_Close,			//	No arguments
	kSimpleAudioDriver_Method_StartHardware,	//	No arguments
	kSimpleAudioDriver_Method_StopHardware,		//	No arguments
	kSimpleAudioDriver_Method_SetSampleRate,	//	One input: the new sample rate as a 64 bit integer
	kSimpleAudioDriver_Method_GetControlValue,	//	One input: the control ID, One output: the control value
	kSimpleAudioDriver_Method_SetControlValue,	//	Two inputs, the control ID and the new value
	kSimpleAudioDriver_Method_NumberOfMethods
};

//	control IDs
enum
{
	kSimpleAudioDriver_Control_MasterInputVolume,
	kSimpleAudioDriver_Control_MasterOutputVolume
};

//	volume control ranges
#define kSimpleAudioDriver_Control_MinRawVolumeValue	0
#define kSimpleAudioDriver_Control_MaxRawVolumeValue	96
#define kSimpleAudioDriver_Control_MinDBVolumeValue		-96.0f
#define kSimpleAudioDriver_Control_MaxDbVolumeValue		0.0f

//	the struct in the status buffer
struct SimpleAudioDriverStatus
{
	volatile uint64_t	mSampleTime;
	volatile uint64_t	mHostTime;
};
typedef struct SimpleAudioDriverStatus	SimpleAudioDriverStatus;

#endif	//	__SimpleAudioDriverTypes_h__
