/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementations of C functions to perform calls to the driver and implement driver lifecycle callbacks.
*/
#include "UserClientCommunication.h"

#include <stdio.h>

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>

// If you don't know what value to use here, it should be identical to the IOUserClass value in your IOKitPersonalities.
// You can double check by searching with the `ioreg` command in your terminal.
// It will be of type "IOUserService" not "IOUserServer"
static const char* dextIdentifier = "NullDriver";

static IONotificationPortRef globalNotificationPort = NULL;
static mach_port_t globalMachNotificationPort;
static CFRunLoopRef globalRunLoop = NULL;
static CFRunLoopSourceRef globalRunLoopSource = NULL;
static io_iterator_t globalDeviceAddedIter = IO_OBJECT_NULL;
static io_iterator_t globalDeviceRemovedIter = IO_OBJECT_NULL;

// MARK: Helpers

const uint32_t MessageType_Scalar = 0;
const uint32_t MessageType_Struct = 1;
const uint32_t MessageType_CheckedScalar = 2;
const uint32_t MessageType_CheckedStruct = 3;
const uint32_t MessageType_RegisterAsyncCallback = 4;
const uint32_t MessageType_AsyncRequest = 5;

typedef struct {
    uint64_t foo;
    uint64_t bar;
} DataStruct;

typedef struct {
    uint64_t foo;
    uint64_t bar;
    uint64_t largeArray[511];
} OversizedDataStruct;

static inline void PrintArray(const uint64_t* ptr, const uint32_t length)
{
    printf("{ ");
    for (uint32_t idx = 0; idx < length; ++idx)
    {
        printf("%llu ", ptr[idx]);
    }
    printf("} \n");
}

static inline void PrintStruct(const DataStruct* ptr)
{
    printf("{\n");
    printf("\t.foo = %llu,\n", ptr->foo);
    printf("\t.bar = %llu,\n", ptr->bar);
    printf("}\n");
}

static inline void PrintOversizedStruct(const OversizedDataStruct* ptr)
{
    printf("{\n");
    printf("\t.foo = %llu,\n", ptr->foo);
    printf("\t.bar = %llu,\n", ptr->bar);
    printf("\t.largeArray[0] = %llu,\n", ptr->largeArray[0]);
    printf("}\n");
}

static inline void PrintErrorDetails(kern_return_t ret)
{
    printf("\tSystem: 0x%02x\n", err_get_system(ret));
    printf("\tSubsystem: 0x%03x\n", err_get_sub(ret));
    printf("\tCode: 0x%04x\n", err_get_code(ret));
}


// MARK: C Constructors/Destructors

bool UserClientSetup(void* refcon)
{
    kern_return_t ret = kIOReturnSuccess;

    globalRunLoop = CFRunLoopGetCurrent();
    if (globalRunLoop == NULL)
    {
        fprintf(stderr, "Failed to initialize globalRunLoop.\n");
        return false;
    }
    CFRetain(globalRunLoop);

    globalNotificationPort = IONotificationPortCreate(kIOMainPortDefault);
    if (globalNotificationPort == NULL)
    {
        fprintf(stderr, "Failed to initialize globalNotificationPort.\n");
        UserClientTeardown();
        return false;
    }

    globalMachNotificationPort = IONotificationPortGetMachPort(globalNotificationPort);
    if (globalMachNotificationPort == 0)
    {
        fprintf(stderr, "Failed to initialize globalMachNotificationPort.\n");
        UserClientTeardown();
        return false;
    }

    globalRunLoopSource = IONotificationPortGetRunLoopSource(globalNotificationPort);
    if (globalRunLoopSource == NULL)
    {
        fprintf(stderr, "Failed to initialize globalRunLoopSource.\n");
        return false;
    }

    // Establish our notifications in the run loop, so we can get callbacks.
    CFRunLoopAddSource(globalRunLoop, globalRunLoopSource, kCFRunLoopDefaultMode);

    /// - Tag: SetUpMatchingNotification
    CFMutableDictionaryRef matchingDictionary = IOServiceNameMatching(dextIdentifier);
    if (matchingDictionary == NULL)
    {
        fprintf(stderr, "Failed to initialize matchingDictionary.\n");
        UserClientTeardown();
        return false;
    }
    matchingDictionary = (CFMutableDictionaryRef)CFRetain(matchingDictionary);
    matchingDictionary = (CFMutableDictionaryRef)CFRetain(matchingDictionary);

    ret = IOServiceAddMatchingNotification(globalNotificationPort, kIOFirstMatchNotification, matchingDictionary, DeviceAdded, refcon, &globalDeviceAddedIter);
    if (ret != kIOReturnSuccess)
    {
        fprintf(stderr, "Add matching notification failed with error: 0x%08x.\n", ret);
        UserClientTeardown();
        return false;
    }
    DeviceAdded(refcon, globalDeviceAddedIter);

    ret = IOServiceAddMatchingNotification(globalNotificationPort, kIOTerminatedNotification, matchingDictionary, DeviceRemoved, refcon, &globalDeviceRemovedIter);
    if (ret != kIOReturnSuccess)
    {
        fprintf(stderr, "Add termination notification failed with error: 0x%08x.\n", ret);
        UserClientTeardown();
        return false;
    }
    DeviceRemoved(refcon, globalDeviceRemovedIter);

    return true;
}

void UserClientTeardown(void)
{
    if (globalRunLoopSource)
    {
        CFRunLoopRemoveSource(globalRunLoop, globalRunLoopSource, kCFRunLoopDefaultMode);
        globalRunLoopSource = NULL;
    }

    if (globalNotificationPort)
    {
        IONotificationPortDestroy(globalNotificationPort);
        globalNotificationPort = NULL;
        globalMachNotificationPort = 0;
    }

    if (globalRunLoop)
    {
        CFRelease(globalRunLoop);
        globalRunLoop = NULL;
    }

    globalDeviceAddedIter = IO_OBJECT_NULL;
    globalDeviceRemovedIter = IO_OBJECT_NULL;
}

// MARK: Asynchronous Events

/// - Tag: DeviceAdded
void DeviceAdded(void* refcon, io_iterator_t iterator)
{
    kern_return_t ret = kIOReturnSuccess;
    io_connect_t connection = IO_OBJECT_NULL;
    io_service_t device = IO_OBJECT_NULL;
    bool attemptedToMatchDevice = false;

    while ((device = IOIteratorNext(iterator)) != IO_OBJECT_NULL)
    {
        attemptedToMatchDevice = true;

        // Open a connection to this user client as a server to that client, and store the instance in "service"
        ret = IOServiceOpen(device, mach_task_self_, 0, &connection);

        if (ret == kIOReturnSuccess)
        {
            fprintf(stdout, "Opened connection to dext.\n");
        }
        else
        {
            fprintf(stderr, "Failed opening connection to dext with error: 0x%08x.\n", ret);
            IOObjectRelease(device);
            return;
        }

        SwiftDeviceAdded(refcon, connection);

        IOObjectRelease(device);
    }
}

void DeviceRemoved(void* refcon, io_iterator_t iterator)
{
    io_service_t device = IO_OBJECT_NULL;

    while ((device = IOIteratorNext(iterator)) != IO_OBJECT_NULL)
    {
        fprintf(stdout, "Closed connection to dext.\n");
        IOObjectRelease(device);
        SwiftDeviceRemoved(refcon);
    }
}

// For more detail on this callback format, view the format of:
// IOAsyncCallback, IOAsyncCallback0, IOAsyncCallback1, IOAsyncCallback2
// Note that the variant of IOAsyncCallback called is based on the number of arguments being returned
// 0 - IOAsyncCallback0
// 1 - IOAsyncCallback1
// 2 - IOAsyncCallback2
// 3+ - IOAsyncCallback
// This is an example of the "IOAsyncCallback" format.
// refcon will be the value you placed in asyncRef[kIOAsyncCalloutRefconIndex]
void AsyncCallback(void* refcon, IOReturn result, void** args, UInt32 numArgs)
{
    uint64_t* arrArgs = (uint64_t*)args;
    DataStruct* output = (DataStruct*)(arrArgs + 1);

    PrintStruct(output);
    SwiftAsyncCallback(refcon, result, args, numArgs);
}

// MARK: Unchecked Actions Sent to Dext

bool UncheckedScalar(io_connect_t connection)
{
    /// - Tag: ClientApp_CallUncheckedScalar
    kern_return_t ret = kIOReturnSuccess;

    // IOConnectCallScalarMethod will fail intentionally for any inputCount or outputCount greater than 16.
    const uint32_t arraySize = 16;
    const uint64_t input[arraySize] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };

    uint32_t outputArraySize = arraySize;
    uint64_t output[arraySize] = {};

    ret = IOConnectCallScalarMethod(connection, MessageType_Scalar, input, arraySize, output, &outputArraySize);
    if (ret != kIOReturnSuccess)
    {
        printf("IOConnectCallScalarMethod failed with error: 0x%08x.\n", ret);
        PrintErrorDetails(ret);
    }

    fprintf(stdout, "Input of size %u: ", arraySize);
    PrintArray(input, arraySize);
    fprintf(stdout, "Output of size %u: ", outputArraySize);
    PrintArray(output, outputArraySize);

    return (ret == kIOReturnSuccess);
}

bool UncheckedStruct(io_connect_t connection)
{
    kern_return_t ret = kIOReturnSuccess;

    const size_t inputSize = sizeof(DataStruct);
    const DataStruct input = { .foo = 300, .bar = 70000 };

    size_t outputSize = sizeof(DataStruct);
    DataStruct output = { .foo = 0, .bar = 0 };

    ret = IOConnectCallStructMethod(connection, MessageType_Struct, &input, inputSize, &output, &outputSize);
    if (ret != kIOReturnSuccess)
    {
        printf("IOConnectCallStructMethod failed with error: 0x%08x.\n", ret);
        PrintErrorDetails(ret);
    }

    printf("Input: \n");
    PrintStruct(&input);
    printf("Output: \n");
    PrintStruct(&output);

    return (ret == kIOReturnSuccess);
}

bool UncheckedLargeStruct(io_connect_t connection)
{
    kern_return_t ret = kIOReturnSuccess;

    const size_t inputSize = sizeof(OversizedDataStruct);
    const OversizedDataStruct input = { };

    size_t outputSize = sizeof(OversizedDataStruct);
    OversizedDataStruct output = { };

    ret = IOConnectCallStructMethod(connection, MessageType_Struct, &input, inputSize, &output, &outputSize);
    if (ret != kIOReturnSuccess)
    {
        printf("IOConnectCallStructMethod failed with error: 0x%08x.\n", ret);
        PrintErrorDetails(ret);
    }

    printf("Input: \n");
    PrintOversizedStruct(&input);
    printf("Output: \n");
    PrintOversizedStruct(&output);

    return (ret == kIOReturnSuccess);
}

// MARK: Checked Actions Sent to Dext

bool CheckedScalar(io_connect_t connection)
{
    /// - Tag: ClientApp_CallCheckedScalar
    kern_return_t ret = kIOReturnSuccess;

    // IOConnectCallScalarMethod will fail intentionally for any inputCount or outputCount other than 16, due to our strict checking in the dext
    const uint32_t arraySize = 16;
    const uint64_t input[arraySize] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 };

    uint32_t outputArraySize = arraySize;
    uint64_t output[arraySize] = {};

    ret = IOConnectCallScalarMethod(connection, MessageType_CheckedScalar, input, arraySize, output, &outputArraySize);
    if (ret != kIOReturnSuccess)
    {
        printf("IOConnectCallScalarMethod failed with error: 0x%08x.\n", ret);
        PrintErrorDetails(ret);
    }

    printf("Input of size %u: ", arraySize);
    PrintArray(input, arraySize);
    printf("Output of size %u: ", outputArraySize);
    PrintArray(output, outputArraySize);

    return (ret == kIOReturnSuccess);
}

bool CheckedStruct(io_connect_t connection)
{
    kern_return_t ret = kIOReturnSuccess;

    const size_t inputSize = sizeof(DataStruct);
    const DataStruct input = { .foo = 300, .bar = 70000 };

    size_t outputSize = sizeof(DataStruct);
    DataStruct output = { .foo = 0, .bar = 0 };

    ret = IOConnectCallStructMethod(connection, MessageType_CheckedStruct, &input, inputSize, &output, &outputSize);
    if (ret != kIOReturnSuccess)
    {
        printf("IOConnectCallStructMethod failed with error: 0x%08x.\n", ret);
        PrintErrorDetails(ret);
    }

    printf("Input: \n");
    PrintStruct(&input);
    printf("Output: \n");
    PrintStruct(&output);

    return (ret == kIOReturnSuccess);
}

bool AssignAsyncCallback(void* refcon, io_connect_t connection)
{
    io_async_ref64_t asyncRef = {};

    // Establish our "AsyncCallback" function as the function that will be called by our Dext when it calls its "AsyncCompletion" function.
    // We'll use kIOAsyncCalloutFuncIndex and kIOAsyncCalloutRefconIndex to define the parameters for our async callback
    // This is your callback function. Check the definition for more details.
    asyncRef[kIOAsyncCalloutFuncIndex] = (io_user_reference_t)AsyncCallback;
    // Use this for context on the return. We'll pass the refcon so we can talk back to the view model.
    asyncRef[kIOAsyncCalloutRefconIndex] = (io_user_reference_t)refcon;

    kern_return_t ret = kIOReturnSuccess;

    const size_t inputSize = sizeof(DataStruct);
    const DataStruct input = { .foo = 300, .bar = 70000 };

    size_t outputSize = sizeof(DataStruct);
    DataStruct output = { .foo = 0, .bar = 0 };

    ret = IOConnectCallAsyncStructMethod(connection, MessageType_RegisterAsyncCallback, globalMachNotificationPort, asyncRef, kIOAsyncCalloutCount, &input, inputSize, &output, &outputSize);
    if (ret != kIOReturnSuccess)
    {
        printf("IOConnectCallStructMethod failed with error: 0x%08x.\n", ret);
        PrintErrorDetails(ret);
    }

    printf("Input: \n");
    PrintStruct(&input);
    printf("Output: \n");
    PrintStruct(&output);

    printf("Async result should match output result.\n");
    printf("Assigned callback to dext. Async actions can now be executed.\n");
    printf("Please wait for the callback...\n");

    return (ret == kIOReturnSuccess);
}

bool SubmitAsyncRequest(io_connect_t connection)
{
    kern_return_t ret = kIOReturnSuccess;

    const size_t inputSize = sizeof(DataStruct);
    const DataStruct input = { .foo = 300, .bar = 70000 };

    ret = IOConnectCallAsyncStructMethod(connection, MessageType_AsyncRequest, globalMachNotificationPort, NULL, 0, &input, inputSize, NULL, NULL);
    if (ret == kIOReturnNotReady)
    {
        printf("No callback has been assigned to the dext, so it cannot respond to the async action.\n");
        printf("Execute the action to assign a callback to the dext before calling this action.\n");
    }
    if (ret != kIOReturnSuccess)
    {
        printf("IOConnectCallStructMethod failed with error: 0x%08x.\n", ret);
        PrintErrorDetails(ret);
    }

    return (ret == kIOReturnSuccess);
}
