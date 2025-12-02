/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Declarations of C functions to perform calls to the driver and implement driver lifecycle callbacks.
*/
#ifndef UserClientCommunication_h
#define UserClientCommunication_h

#include <IOKit/IOTypes.h>

extern void SwiftAsyncCallback(void* refcon, IOReturn result, void** args, UInt32 numArgs);
void AsyncCallback(void* refcon, IOReturn result, void** args, UInt32 numArgs);

extern void SwiftDeviceAdded(void* refcon, io_connect_t connection);
extern void SwiftDeviceRemoved(void* refcon);
void DeviceAdded(void* refcon, io_iterator_t iterator);
void DeviceRemoved(void* refcon, io_iterator_t iterator);

bool UserClientSetup(void* refcon);
void UserClientTeardown(void);

bool UncheckedScalar(io_connect_t connection);
bool UncheckedStruct(io_connect_t connection);
bool UncheckedLargeStruct(io_connect_t connection);
bool CheckedScalar(io_connect_t connection);
bool CheckedStruct(io_connect_t connection);
bool AssignAsyncCallback(void* refcon, io_connect_t connection);
bool SubmitAsyncRequest(io_connect_t connection);

#endif /* UserClientCommunication_h */
