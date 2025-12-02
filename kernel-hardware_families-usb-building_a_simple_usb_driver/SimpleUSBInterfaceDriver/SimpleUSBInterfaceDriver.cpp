/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Sample USB interface driver.
*/

#include "SimpleUSBInterfaceDriver.h"
#include "debug.h"


#define debug(mask, fmt, args...) debugLog(mask, SimpleUSBInterfaceDriver, fmt,##args)


OSDefineMetaClassAndStructors(SimpleUSBInterfaceDriver, IOService);


#pragma mark -
#pragma mark IOKit Lifecycle Methods


// Initializes the driver
// Returns an Boolean indicating if driver initializes successfully (true) or
// unsuccessfully (false).
/// - Tag: initMethod
bool
SimpleUSBInterfaceDriver::init (OSDictionary *dictionary)
{
    bool     result   = false;
    uint32_t bootArgs = 0;


    // Check the boot-args for what logging should be enabled
    PE_parse_boot_argn("SimpleUSBInterfaceDriver-debug", &bootArgs, sizeof(bootArgs));
    _debugLoggingMask |= (bootArgs | kSimpleUSBInterfaceDriverDebug_Always);
    _debugLoggingMask = 0xFF;

    debug(kSimpleUSBInterfaceDriverDebug_Init, "calling init()\n");


    result = super::init(dictionary);
    __Require(true == result, Exit);

    _interruptReadPending = false;

Exit:
    debug(kSimpleUSBInterfaceDriverDebug_Init, "%s\n", (result == true) ? "success" : "fail");
    return result;
}


// Starts the driver
// Returns an Boolean indicating driver starts successfully (true) or
// unsuccessfully (false).
/// - Tag: startMethod
bool
SimpleUSBInterfaceDriver::start (IOService *provider)
{
    bool     result = false;
    IOReturn status = kIOReturnError;


    debug(kSimpleUSBInterfaceDriverDebug_Init, "\n");


    result = super::start(provider);
    __Require(true == result, Exit);


    debug(kSimpleUSBInterfaceDriverDebug_Verbose, "validating the provider\n");

    _interface = OSDynamicCast(IOUSBHostInterface, provider);
    __Require_Action(NULL != _interface, Exit, result = false; stop(provider));
    _interface->retain();


    debug(kSimpleUSBInterfaceDriverDebug_Verbose, "opening the interface for exclusive access\n");

    result = _interface->open(this);
    __Require_Action(true == result, Exit, stop(provider));

    // Every device has a work loop that is shared among its interfaces to be used by drivers
    _workLoop = _interface->getWorkLoop();
    __Require_Action(NULL != _workLoop, Exit, result = false;
                     stop(provider));
    _workLoop->retain();

    _commandGate = IOCommandGate::commandGate(this);
    __Require_Action(NULL != _workLoop, Exit, result = false;
                     stop(provider));
    _workLoop->addEventSource(_commandGate);

    debug(kSimpleUSBInterfaceDriverDebug_Verbose, "searching for the interrupt pipe\n");

    status = findPipe(kEndpointDirectionIn, kEndpointTypeInterrupt, &_maxPacketSize, &_interruptInPipe);
    __Require_Action(kIOReturnSuccess == status, Exit, result = false; stop(provider));


    debug(kSimpleUSBInterfaceDriverDebug_Verbose, "allocating the I/O buffer\n");

    _interruptPacketBuffer = _interface->createIOBuffer(kIODirectionIn, _maxPacketSize);
    __Require_Action(NULL != _interruptPacketBuffer, Exit, result = false; stop(provider));


    debug(kSimpleUSBInterfaceDriverDebug_Verbose, "starting the async read\n");

    status = readInterruptPipe();
    __Require_Action(kIOReturnSuccess == status, Exit, result = false; stop(provider));

    result = true;

Exit:
    debug(kSimpleUSBInterfaceDriverDebug_Init, "%s\n", (result == true) ? "success" : "fail");
    return result;
}


// Terminates the driver
// Returns an Boolean indicating if the driver terminated successfully (true) or
// unsuccessfully (false).
/// - Tag: terminateMethod
bool
SimpleUSBInterfaceDriver::terminate (IOOptionBits options)
{
    debug(kSimpleUSBInterfaceDriverDebug_Init, "calling terminate()\n");


    // Close the device on unplug
    if ((NULL != _interface) && (_interface->isOpen(this))) {
        // This will synchronously abort any I/O
        _interface->close(this);
    }

    return super::terminate(options);
}


// Stops the driver
// Returns an Boolean indicating if the driver stopped successfully (true) or
// unsuccessfully (false).
/// - Tag: stopMethod
void
SimpleUSBInterfaceDriver::stop (IOService *provider)
{
    debug(kSimpleUSBInterfaceDriverDebug_Init, "\n");


    // Close the device if start failed
    if ((NULL != _interface) && (_interface->isOpen(this))) {
        _interface->close(this);
    }

    if (_workLoop != NULL) {
        if (_commandGate != NULL) {
            _workLoop->removeEventSource(_commandGate);
        }
    }

    super::stop(provider);
}


void
SimpleUSBInterfaceDriver::free (void)
{
    debug(kSimpleUSBInterfaceDriverDebug_Init, "\n");

    OSSafeReleaseNULL(_interface);
    OSSafeReleaseNULL(_interruptInPipe);
    OSSafeReleaseNULL(_commandGate);
    OSSafeReleaseNULL(_workLoop);
    OSSafeReleaseNULL(_interruptPacketBuffer);

    super::free();
}


#pragma mark -
#pragma mark SimpleUSBInterfaceDriver Methods

IOReturn
SimpleUSBInterfaceDriver::findPipe (uint8_t         direction,
                                    uint8_t         type,
                                    uint16_t       *maxPacketSize,
                                    IOUSBHostPipe **pipe)
{
    kern_return_t                               status              = kIOReturnNotFound;
    const StandardUSB::ConfigurationDescriptor *configDescriptor    = NULL;
    const StandardUSB::InterfaceDescriptor     *interfaceDescriptor = NULL;
    const StandardUSB::EndpointDescriptor      *endpointDescriptor  = NULL;


    debug(kSimpleUSBInterfaceDriverDebug_Init, "\n");

    configDescriptor = _interface->getConfigurationDescriptor();
    __Require(NULL != configDescriptor, Exit);

    interfaceDescriptor = _interface->getInterfaceDescriptor();
    __Require(NULL != interfaceDescriptor, Exit);

    while ((endpointDescriptor = StandardUSB::getNextEndpointDescriptor(configDescriptor, interfaceDescriptor, endpointDescriptor)) != NULL) {
        if (   (StandardUSB::getEndpointType(endpointDescriptor)       == type)
            && (StandardUSB::getEndpointDirection(endpointDescriptor)  == direction))
        {
            *pipe = _interface->copyPipe(endpointDescriptor->bEndpointAddress);
            __Require(*pipe != NULL, Exit);

            if (NULL != maxPacketSize) {
                *maxPacketSize = USBToHost16(endpointDescriptor->wMaxPacketSize);
            }

            status = kIOReturnSuccess;
            break;
        }
    }

Exit:
    return status;
}


IOReturn
SimpleUSBInterfaceDriver::readInterruptPipe (void)
{
    IOReturn status = kIOReturnError;


    debug(kSimpleUSBInterfaceDriverDebug_IO, "\n");


    __Require_Action(!isInactive(), Exit, status = kIOReturnOffline);

    _interruptCompletion.owner  = this;
    _interruptCompletion.action = OSMemberFunctionCast(IOUSBHostCompletionAction,
                                                       this,
                                                       &SimpleUSBInterfaceDriver::interruptReadComplete);

    status = _commandGate->runAction(OSMemberFunctionCast(IOCommandGate::Action,
                                                          this,
                                                          &SimpleUSBInterfaceDriver::readInterruptPipeGated));
Exit:
    return status;
}


IOReturn
SimpleUSBInterfaceDriver::readInterruptPipeGated (void)
{
    IOReturn status = kIOReturnError;


    debug(kSimpleUSBInterfaceDriverDebug_IO, "\n");

    __Require_Action(!isInactive(), Exit, status = kIOReturnOffline);
    __Require_Action(false == _interruptReadPending, Exit, status = kIOReturnSuccess);


    bzero(_interruptPacketBuffer->getBytesNoCopy(), _maxPacketSize);

    status = _interruptInPipe->io(_interruptPacketBuffer,
                                  static_cast < uint32_t > (_interruptPacketBuffer->getLength()),
                                  &_interruptCompletion,
                                  0);

    if (kUSBHostReturnPipeStalled == status) {
        _interruptInPipe->clearStall(true);

        status = _interruptInPipe->io(_interruptPacketBuffer,
                                      static_cast < uint32_t > (_interruptPacketBuffer->getLength()),
                                      &_interruptCompletion,
                                      0);
    }

    __Require(kIOReturnSuccess == status, Exit);

    _interruptReadPending = true;

Exit:
    return status;
}


void
SimpleUSBInterfaceDriver::interruptReadComplete (void    *param,
                                                 IOReturn status,
                                                 UInt32   bytesTransferred)
{
    debug(kSimpleUSBInterfaceDriverDebug_IO, "%u bytes completed with %s\n", bytesTransferred, _interface->stringFromReturn(status));


    _interruptReadPending = false;

    __Require(kIOReturnSuccess == status, Exit);

    // This is delivered with the gate lock held so just call the gated method directly
    readInterruptPipeGated();

Exit:
    return;
}

