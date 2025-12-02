/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A minimal user-space driver.
*/

/*==================================================================================================
	SA_Device.h
==================================================================================================*/
#if !defined(__SA_Device_h__)
#define __SA_Device_h__

//==================================================================================================
//	Includes
//==================================================================================================

//	SuperClass Includes
#include "SA_Object.h"

//	Local Includes
#include "SA_IOKit.h"

//	PublicUtility Includes
#include "CACFString.h"
#include "CAMutex.h"
#include "CAVolumeCurve.h"

//==================================================================================================
//	Types
//==================================================================================================

struct	SimpleAudioDriverStatus;

//==================================================================================================
//	SA_Device
//==================================================================================================

class SA_Device
:
	public SA_Object
{

#pragma mark Construction/Destruction
public:
								SA_Device(AudioObjectID inObjectID, io_object_t inIOObject);
					
	virtual void				Activate();
	virtual void				Deactivate();

protected:
	virtual						~SA_Device();
	
#pragma mark Property Operations
public:
	virtual bool				HasProperty(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const;
	virtual bool				IsPropertySettable(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const;
	virtual UInt32				GetPropertyDataSize(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData) const;
	virtual void				GetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, UInt32& outDataSize, void* outData) const;
	virtual void				SetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, const void* inData);

#pragma mark Device Property Operations
private:
	bool						Device_HasProperty(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const;
	bool						Device_IsPropertySettable(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const;
	UInt32						Device_GetPropertyDataSize(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData) const;
	void						Device_GetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, UInt32& outDataSize, void* outData) const;
	void						Device_SetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, const void* inData);

#pragma mark Stream Property Operations
private:
	bool						Stream_HasProperty(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const;
	bool						Stream_IsPropertySettable(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const;
	UInt32						Stream_GetPropertyDataSize(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData) const;
	void						Stream_GetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, UInt32& outDataSize, void* outData) const;
	void						Stream_SetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, const void* inData);

#pragma mark Control Property Operations
private:
	bool						Control_HasProperty(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const;
	bool						Control_IsPropertySettable(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const;
	UInt32						Control_GetPropertyDataSize(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData) const;
	void						Control_GetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, UInt32& outDataSize, void* outData) const;
	void						Control_SetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, const void* inData);

#pragma mark IO Operations
public:
	void						StartIO();
	void						StopIO();
	void						GetZeroTimeStamp(Float64& outSampleTime, UInt64& outHostTime, UInt64& outSeed) const;
	
	void						WillDoIOOperation(UInt32 inOperationID, bool& outWillDo, bool& outWillDoInPlace) const;
	void						BeginIOOperation(UInt32 inOperationID, UInt32 inIOBufferFrameSize, const AudioServerPlugInIOCycleInfo& inIOCycleInfo);
	void						DoIOOperation(AudioObjectID inStreamObjectID, UInt32 inOperationID, UInt32 inIOBufferFrameSize, const AudioServerPlugInIOCycleInfo& inIOCycleInfo, void* ioMainBuffer, void* ioSecondaryBuffer);
	void						EndIOOperation(UInt32 inOperationID, UInt32 inIOBufferFrameSize, const AudioServerPlugInIOCycleInfo& inIOCycleInfo);

private:
	void						ReadInputData(UInt32 inIOBufferFrameSize, Float64 inSampleTime, void* outBuffer);
	void						WriteOutputData(UInt32 inIOBufferFrameSize, Float64 inSampleTime, const void* inBuffer);

#pragma mark Hardware Accessors
public:
	static CFStringRef			HW_CopyDeviceUID(io_object_t inIOObject);
	
private:
	void						_HW_Open();
	void						_HW_Close();
	kern_return_t				_HW_StartIO();
	void						_HW_StopIO();
	UInt64						_HW_GetSampleRate() const;
	kern_return_t				_HW_SetSampleRate(UInt64 inNewSampleRate);
	UInt32						_HW_GetRingBufferFrameSize() const;
	SInt32						_HW_GetVolumeControlValue(int inControlID) const;
	kern_return_t				_HW_SetVolumeControlValue(int inControlID, SInt32 inNewControlValue);

#pragma mark Implementation
public:
	io_object_t					GetIOKitObject() const	{ return mIOKitObject.GetObject(); }
	CFStringRef					CopyDeviceUID() const	{ return mDeviceUID.CopyCFString(); }
	void						PerformConfigChange(UInt64 inChangeAction, void* inChangeInfo);
	void						AbortConfigChange(UInt64 inChangeAction, void* inChangeInfo);

private:
	enum
	{
								kNumberOfSubObjects					= 4,
								kNumberOfInputSubObjects			= 2,
								kNumberOfOutputSubObjects			= 2,
								
								kNumberOfStreams					= 2,
								kNumberOfInputStreams				= 1,
								kNumberOfOutputStreams				= 1,
								
								kNumberOfControls					= 2
	};
	
	#define kDeviceUIDPattern	"SimpleAudioDevice-%d"
	#define kDeviceModelUID		"SimpleAudioDeviceModelUID"
	
	CAMutex						mStateMutex;
	CAMutex						mIOMutex;
	SA_IOKitObject				mIOKitObject;
	CACFString					mDeviceUID;
	UInt64						mStartCount;
	UInt64						mSampleRateShadow;
	UInt32						mRingBufferFrameSize;
	SimpleAudioDriverStatus*	mDriverStatus;
	
	AudioObjectID				mInputStreamObjectID;
	bool						mInputStreamIsActive;
	Byte*						mInputStreamRingBuffer;
	
	AudioObjectID				mOutputStreamObjectID;
	bool						mOutputStreamIsActive;
	Byte*						mOutputStreamRingBuffer;
	
	AudioObjectID				mInputMasterVolumeControlObjectID;
	SInt32						mInputMasterVolumeControlRawValueShadow;
	AudioObjectID				mOutputMasterVolumeControlObjectID;
	SInt32						mOutputMasterVolumeControlRawValueShadow;
	CAVolumeCurve				mVolumeCurve;

};

#endif	//	__SA_Device_h__
