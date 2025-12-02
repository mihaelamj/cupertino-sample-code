/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Sample USB interface driver.
*/

//
// SimpleUSBInterfaceDriver
//
// This project shows how to match on an IOUSBHostInterface service, create pipes, and perform I/O.  It also contains
// implementations of the IOKit lifecycle methods.
//
// Matching options
// Probe score 100000: idVendor + idProduct + bInterfaceNumber + bConfigurationValue + bcdDevice.
// Probe score 90000:  idVendor + idProduct + bInterfaceNumber + bConfigurationValue.
// Probe score 80000:  idVendor + bInterfaceSubClass + bInterfaceProtocol.  Only if bInterfaceClass is 0xFF.
// Probe score 70000:  idVendor + bInterfaceSubClass.  Only if bInterfaceClass is 0xFF.
// Probe score 60000:  bInterfaceClass + bInterfaceSubClass + bInterfaceProtocol. Only if bInterfaceClass is not 0xFF.
// Probe score 50000:  bInterfaceClass + bInterfaceSubClass.  Only if bInterfaceClass is not 0xFF
//
// Also, this project has -Wno-inconsistent-missing-override added to the "Other C++ flags" build option.
//
// Copyright (c) 2020 Apple, Inc. All rights reserved.
//

#ifndef _SimpleUSBInterfaceDriver_h_
#define _SimpleUSBInterfaceDriver_h_


#include <IOKit/usb/IOUSBHostInterface.h>


class SimpleUSBInterfaceDriver: public IOService
{
    OSDeclareDefaultStructors(SimpleUSBInterfaceDriver)

    typedef IOService super;

public:
    bool
    init (OSDictionary *dictionary = 0) override;


    bool
    start (IOService *provider) override;


    bool
    terminate (IOOptionBits options = 0) override;


    void
    stop (IOService *provider) override;


    void
    free (void) override;


protected:
    virtual void
    interruptReadComplete (void    *param,
                           IOReturn status,
                           UInt32   bytesTransferred);


    virtual IOReturn
    readInterruptPipe (void);


    virtual IOReturn
    readInterruptPipeGated (void);


    virtual IOReturn
    findPipe (uint8_t         direction,
              uint8_t         type,
              uint16_t       *maxPacketSize,
              IOUSBHostPipe **pipe);


    IOUSBHostCompletion       _interruptCompletion;
    IOUSBHostInterface       *_interface;
    IOUSBHostPipe            *_interruptInPipe;
    IOBufferMemoryDescriptor *_interruptPacketBuffer;
    IOCommandGate            *_commandGate;
    IOWorkLoop               *_workLoop;
    uint32_t                  _debugLoggingMask;
    uint16_t                  _maxPacketSize;
    bool                      _interruptReadPending;
};


#endif

