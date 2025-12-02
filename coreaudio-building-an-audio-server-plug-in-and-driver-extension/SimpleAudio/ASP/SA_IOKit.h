/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A minimal user-space driver.
*/

/*==================================================================================================
	SA_IOKit.h
==================================================================================================*/
#if !defined(__SA_IOKit_h__)
#define __SA_IOKit_h__

//==================================================================================================
//	Includes
//==================================================================================================

//	PublicUtility Includes
#include "CACFDictionary.h"
#include "CACFObject.h"

//	System Includes
#include <IOKit/IOKitLib.h>

//==================================================================================================
//	_IOAudioNotificationMessage64
//	
//	This is a replacement for IOAudioNotificationMessage that will work for both 32 and 64 bit
//	clients. Note that this assumes a 64 bit kernel.
//==================================================================================================

#if TARGET_RT_64_BIT

typedef struct _IOAudioNotificationMessage64 {
    mach_msg_header_t	messageHeader;
    UInt32		type;
    UInt32		ref;
    void *		sender;
} _IOAudioNotificationMessage64;

#else

typedef struct _IOAudioNotificationMessage64 {
    mach_msg_header_t	messageHeader;
    UInt32		type;
    UInt32		ref;
	UInt32		reserved;
    void *		sender;
} _IOAudioNotificationMessage64;

#endif

//==================================================================================================
//	SA_IOKitObject
//==================================================================================================

class SA_IOKitObject
{

#pragma mark Construction/Destruction
public:
						SA_IOKitObject();
						SA_IOKitObject(io_object_t inObject);
						SA_IOKitObject(const SA_IOKitObject& inObject);
	SA_IOKitObject&		operator=(const SA_IOKitObject& inObject);
	virtual				~SA_IOKitObject();

#pragma mark Attributes
public:
	io_object_t			GetObject() const;
	io_object_t			CopyObject();
	bool				IsValid() const;
	bool				IsEqualTo(io_object_t inObject) const;
	bool				ConformsTo(const io_name_t inClassName);
	bool				IsServiceAlive() const;
	void				ServiceWasTerminated();
	bool				TestForLiveness() const															{ return TestForLiveness(mObject); }
	void				SetAlwaysLoadPropertiesFromRegistry(bool inAlwaysLoadPropertiesFromRegistry)	{ mAlwaysLoadPropertiesFromRegistry = inAlwaysLoadPropertiesFromRegistry; }
	
	static bool			TestForLiveness(io_object_t inObject);
	
#pragma mark Registry Operations
public:
	bool				HasProperty(CFStringRef inKey, bool inIsInUserDictionary) const;
	bool				CopyProperty_bool(CFStringRef inKey, bool inIsInUserDictionary, bool& outValue) const;
	bool				CopyProperty_SInt32(CFStringRef inKey, bool inIsInUserDictionary, SInt32& outValue) const;
	bool				CopyProperty_UInt32(CFStringRef inKey, bool inIsInUserDictionary, UInt32& outValue) const;
	bool				CopyProperty_UInt64(CFStringRef inKey, bool inIsInUserDictionary, UInt64& outValue) const;
	bool				CopyProperty_Fixed32(CFStringRef inKey, bool inIsInUserDictionary, Float32& outValue) const;
	bool				CopyProperty_Fixed64(CFStringRef inKey, bool inIsInUserDictionary, Float64& outValue) const;
	bool				CopyProperty_CFString(CFStringRef inKey, bool inIsInUserDictionary, CFStringRef& outValue) const;
	bool				CopyProperty_CFArray(CFStringRef inKey, bool inIsInUserDictionary, CFArrayRef& outValue) const;
	bool				CopyProperty_CFDictionary(CFStringRef inKey, bool inIsInUserDictionary, CFDictionaryRef& outValue) const;
	bool				CopyProperty_CFType(CFStringRef inKey, bool inIsInUserDictionary, CFTypeRef& outValue) const;
	
	void				CopyProperty_CACFString(CFStringRef inKey, bool inIsInUserDictionary, CACFString& outValue) const;
	void				CopyProperty_CACFArray(CFStringRef inKey, bool inIsInUserDictionary, CACFArray& outValue) const;
	void				CopyProperty_CACFDictionary(CFStringRef inKey, bool inIsInUserDictionary, CACFDictionary& outValue) const;
	
	virtual void		PropertiesChanged();
	virtual void		CacheProperties() const;

#pragma mark Static Registry Operations
public:
	static bool			CopyProperty_bool(io_object_t inObject, CFStringRef inKey, bool inIsInUserDictionary, bool& outValue);
	static bool			CopyProperty_SInt32(io_object_t inObject, CFStringRef inKey, bool inIsInUserDictionary, SInt32& outValue);
	static bool			CopyProperty_UInt32(io_object_t inObject, CFStringRef inKey, bool inIsInUserDictionary, UInt32& outValue);
	static bool			CopyProperty_CFString(io_object_t inObject, CFStringRef inKey, bool inIsInUserDictionary, CFStringRef& outValue);
	static bool			CopyProperty_CFArray(io_object_t inObject, CFStringRef inKey, bool inIsInUserDictionary, CFArrayRef& outValue);
	static bool			CopyProperty_CFDictionary(io_object_t inObject, CFStringRef inKey, bool inIsInUserDictionary, CFDictionaryRef& outValue);
	
	static void			CopyProperty_CACFString(io_object_t inObject, CFStringRef inKey, bool inIsInUserDictionary, CACFString& outValue);

#pragma mark Connection Operations
public:
	bool				IsConnectionOpen() const;
	void				OpenConnection(UInt32 inUserClientType = 0);
	void				CloseConnection();
	void				SetConnectionNotificationPort(UInt32 inType, mach_port_t inPort, void* inUserData);
	void*				MapMemory(UInt32 inType, IOOptionBits inOptions, UInt32& outSize);
	void				ReleaseMemory(void* inMemory, UInt32 inType);
	kern_return_t		CallMethod(UInt32 inSelector, const UInt64* inInputItems, UInt32 inNumberInputItems, const void* inRawInput, size_t inRawInputSize, UInt64* outOutputItems, UInt32* outNumberOutputItems, void* outRawOutput, size_t* outRawOutputSize);
	kern_return_t		CallTrap(UInt32 inSelector);
	
#pragma mark Implementation
public:
	virtual void		Retain();
	virtual void		Release();

protected:
	io_object_t			mObject;
	io_connect_t		mConnection;
	CACFDictionary		mProperties;
	CACFDictionary		mUserProperties;
	bool				mAlwaysLoadPropertiesFromRegistry;
	bool				mIsAlive;

};

//==================================================================================================
//	SA_IOKitIterator
//==================================================================================================

class SA_IOKitIterator
{

#pragma mark Construction/Destruction
public:
						SA_IOKitIterator();
						SA_IOKitIterator(io_iterator_t inIterator, bool inWillRelease = true);
						SA_IOKitIterator(const SA_IOKitIterator& inIterator);
						SA_IOKitIterator(io_object_t inParent, const io_name_t inPlane);
						SA_IOKitIterator(io_object_t inChild, const io_name_t inPlane, bool);
						SA_IOKitIterator(CFMutableDictionaryRef inMatchingDictionary);
	SA_IOKitIterator&	operator=(io_iterator_t inIterator);
	SA_IOKitIterator&	operator=(const SA_IOKitIterator& inIterator);
						~SA_IOKitIterator();

#pragma mark Operations
public:
	io_iterator_t		GetIterator() const;
	bool				IsValid() const;
	SA_IOKitObject		Next();
	void				SetWillRelease(bool inWillRelease);
	
#pragma mark Implementation
private:
	void				Retain();
	void				Release();
	
	io_iterator_t		mIterator;
	bool				mWillRelease;

};

#endif	//	__SA_IOKit_h__
