/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A DriverKit null driver implementation that only logs interactions with its client.
*/

#include <os/log.h>

#include <DriverKit/IOLib.h>

#include "NullDriver.h"
#include "NullDriverUserClient.h"

// This log to makes it easier to parse out individual logs from the driver, since all logs will be prefixed with the same word/phrase.
// DriverKit logging has no logging levels; some developers might want to prefix errors differently than info messages.
// Another option is to #define a "debug" case where some log messages only exist when doing a debug build.
// To search for logs from this driver, use either: `sudo dmesg | grep NullDriver` or use Console.app search to find messages that start with "NullDriver -".
#define Log(fmt, ...) os_log(OS_LOG_DEFAULT, "NullDriver Base - " fmt "\n", ##__VA_ARGS__)

struct NullDriver_IVars {
    NullDriverUserClient* userClient = nullptr;
};


// MARK: Dext Lifecycle Management
bool NullDriver::init(void)
{
    bool result = false;

    Log("init()");

    result = super::init();
    if (result != true)
    {
        Log("init() - super::init failed.");
        goto Exit;
    }

    ivars = IONewZero(NullDriver_IVars, 1);
    if (ivars == nullptr)
    {
        Log("init() - Failed to allocate memory for ivars.");
        goto Exit;
    }

    Log("init() - Finished.");
    return true;

Exit:
    return false;
}

kern_return_t NullDriver::Start_Impl(IOService* provider)
{
    kern_return_t ret = kIOReturnSuccess;

    ret = Start(provider, SUPERDISPATCH);
    if (ret != kIOReturnSuccess)
    {
        Log("Start() - super::Start failed with error: 0x%08x.", ret);
        goto Exit;
    }

    ret = RegisterService();
    if (ret != kIOReturnSuccess)
    {
        Log("Start() - Failed to register service with error: 0x%08x.", ret);
        goto Exit;
    }

    Log("Start() - Finished.");
    ret = kIOReturnSuccess;

Exit:
    return ret;
}

kern_return_t NullDriver::Stop_Impl(IOService* provider)
{
    kern_return_t ret = kIOReturnSuccess;
    Log("Stop()");

    // The user client will clean itself up, no need to clean it up here.

    ret = Stop(provider, SUPERDISPATCH);
    if (ret != kIOReturnSuccess)
    {
        Log("Stop() - super::Stop failed with error: 0x%08x.", ret);
    }

    Log("Stop() - Finished.");

    return ret;
}

void NullDriver::free(void)
{
    Log("free()");

    OSSafeReleaseNULL(ivars->userClient);
    IOSafeDeleteNULL(ivars, NullDriver_IVars, 1);

    super::free();
}

// When an application attaches to the dext via IOServiceOpen, this method runs as a callback.
kern_return_t NullDriver::NewUserClient_Impl(uint32_t type, IOUserClient** userClient)
{
    kern_return_t ret = kIOReturnSuccess;
    IOService* client = nullptr;

    Log("NewUserClient()");

    ret = Create(this, "UserClientProperties", &client);
    if (ret != kIOReturnSuccess)
    {
        Log("NewUserClient() - Failed to create UserClientProperties with error: 0x%08x.", ret);
        goto Exit;
    }

    *userClient = OSDynamicCast(NullDriverUserClient, client);
    if (*userClient == NULL)
    {
        Log("NewUserClient() - Failed to cast new client.");
        client->release();
        ret = kIOReturnError;
        goto Exit;
    }

    Log("NewUserClient() - Finished.");

Exit:
    return ret;
}
