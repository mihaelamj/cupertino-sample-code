/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A minimal user-space driver.
*/

/*==================================================================================================
	SA_PlugIn.h
==================================================================================================*/
#if !defined(__SA_PlugIn_h__)
#define __SA_PlugIn_h__

//==================================================================================================
//	Includes
//==================================================================================================

//	SuperClass Includes
#include "SA_Object.h"

//	PublicUtility Includes
#include "CADispatchQueue.h"

//	System Includes
#include <IOKit/IOKitLib.h>

//==================================================================================================
//	Types
//==================================================================================================

class	SA_Device;

//==================================================================================================
//	SA_PlugIn
//==================================================================================================

class SA_PlugIn
:
	public SA_Object
{

#pragma mark Construction/Destruction
public:
	static SA_PlugIn&				GetInstance();

protected:
									SA_PlugIn();
	virtual							~SA_PlugIn();

	virtual void					Activate();
	virtual void					Deactivate();
	
private:
	static void						StaticInitializer();

#pragma mark Property Operations
public:
	virtual bool					HasProperty(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const;
	virtual bool					IsPropertySettable(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress) const;
	virtual UInt32					GetPropertyDataSize(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData) const;
	virtual void					GetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, UInt32& outDataSize, void* outData) const;
	virtual void					SetPropertyData(AudioObjectID inObjectID, pid_t inClientPID, const AudioObjectPropertyAddress& inAddress, UInt32 inQualifierDataSize, const void* inQualifierData, UInt32 inDataSize, const void* inData);

#pragma mark Device List Management
private:
	void							_StartDeviceListNotifications();
	void							_StopDeviceListNotifications();
	
	void							AddDevice(SA_Device* inDevice);
	void							RemoveDevice(SA_Device* inDevice);
	SA_Device*						CopyDeviceByIOObject(io_object_t inIOObject);
	
	void							_AddDevice(SA_Device* inDevice);
	void							_RemoveDevice(SA_Device* inDevice);
	void							_RemoveAllDevices();
	SA_Device*						_CopyDeviceByIOObject(io_object_t inIOObject);
	
	static void						IOServiceMatchingHandler(void* inContext, io_iterator_t inIterator);
	static void						IOServiceInterestHandler(void* inContext, io_service_t inService, natural_t inMessageType, void* inMessageArgument);

	struct							DeviceInfo
	{
		AudioObjectID				mDeviceObjectID;
		io_object_t					mInterestNotification;
		
									DeviceInfo() : mDeviceObjectID(0), mInterestNotification(IO_OBJECT_NULL) {}
									DeviceInfo(AudioObjectID inDeviceObjectID) : mDeviceObjectID(inDeviceObjectID), mInterestNotification(IO_OBJECT_NULL) {}
	};
	typedef std::vector<DeviceInfo>	DeviceInfoList;
	
	DeviceInfoList					mDeviceInfoList;
	IONotificationPortRef			mIOKitNotificationPort;
	io_iterator_t					mMatchingNotification;
	CADispatchQueue					mDispatchQueue;

#pragma mark Host Accesss
public:
	static void						SetHost(AudioServerPlugInHostRef inHost)	{ sHost = inHost; }
	
	static void						Host_PropertiesChanged(AudioObjectID inObjectID, UInt32 inNumberAddresses, const AudioObjectPropertyAddress inAddresses[])	{ if(sHost != NULL) { sHost->PropertiesChanged(GetInstance().sHost, inObjectID, inNumberAddresses, inAddresses); } }
	static void						Host_RequestDeviceConfigurationChange(AudioObjectID inDeviceObjectID, UInt64 inChangeAction, void* inChangeInfo)			{ if(sHost != NULL) { sHost->RequestDeviceConfigurationChange(GetInstance().sHost, inDeviceObjectID, inChangeAction, inChangeInfo); } }

#pragma mark Implementation
private:
	CAMutex							mMutex;
	
	static pthread_once_t			sStaticInitializer;
	static SA_PlugIn*				sInstance;
	static AudioServerPlugInHostRef	sHost;

};

#endif	//	__SA_PlugIn_h__
