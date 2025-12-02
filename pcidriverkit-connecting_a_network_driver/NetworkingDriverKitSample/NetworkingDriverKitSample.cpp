/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The driver's implementation of NetworkingDriverKit API methods, and
            methods specific to the driver.
*/

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <os/log.h>
#include <DriverKit/IOLib.h>
#include <DriverKit/IODispatchQueue.h>
#include <DriverKit/IOTimerDispatchSource.h>
#include <DriverKit/OSAction.h>

#include <NetworkingDriverKit/NetworkingDriverKit.h>
#include "NetworkingDriverKitSample.h"
#include "NetworkingDriverKitDebug.h"

#undef super
#define super IOUserNetworkEthernet

//
// Instance variables associated with the device.
//
struct NetworkingDriverKitSample_IVars
{
    IODispatchQueue *                   dsQueue;
    IOUserNetworkPacketBufferPool *     pool;
    IOUserNetworkTxSubmissionQueue *    txsQueue;
    IOUserNetworkTxCompletionQueue *    txcQueue;
    IOUserNetworkRxSubmissionQueue *    rxsQueue;
    IOUserNetworkRxCompletionQueue *    rxcQueue;
    OSAction *                          txPacketAction;
    IOUserNetworkMediaType              chosenMediaType;
    IOUserNetworkMediaType              activeMediaType;
    IOTimerDispatchSource               *receiveTimerSource;
    OSAction                            *receiveTimer;
    bool                                enable;
};

uint32_t ndks_debug;

//
// The init routine allocates instance variables and initialises all
// variables for the device instance, prior to start.
//
bool
NetworkingDriverKitSample::init()
{
    if (!super::init()) return false;

    ivars = (NetworkingDriverKitSample_IVars *)IOMallocZero(sizeof(NetworkingDriverKitSample_IVars));
    
    ivars->chosenMediaType = kIOUserNetworkMediaEthernetAuto;
    ivars->activeMediaType = kIOUserNetworkMediaEthernet1000BaseT;

    return (true);
}

//
// The Start routine prepares the interface for usage by the networking stack,
// creating the queues and callbacks and registering the intefaces with the networking
// stack and service tree.
//
//
kern_return_t
IMPL(NetworkingDriverKitSample, Start)
{
    IOReturn ret;
    bool status;
    IOUserNetworkPacketQueue *queues[4];
    IODataQueueDispatchSource *dataQueue = NULL;
    struct IOUserNetworkPacketBufferPoolOptions poolOptions;
    bool ndks_enable;

    static const IOUserNetworkMACAddress macAddress = {
        .octet = {0x10, 0x22, 0x33, 0x44, 0x55, 0x66}
    };

    static const IOUserNetworkMediaType mediaTable[3] = {
        kIOUserNetworkMediaEthernetAuto,
        kIOUserNetworkMediaEthernet100BaseTX,
        kIOUserNetworkMediaEthernet1000BaseT
    };

    DLOG("==> %p (%p)", this, provider);
    
    ret = kIOReturnError;
    status = false;
    
    //
    // NVRAM boot args are normally picked up early in the driver start routine. In this
    // case the boot arg 'ndks-enable' controls whether this driver is allowed to run or not.
    //
    ndks_enable = true;
    IOParseBootArgNumber("ndks-enable", &ndks_enable, sizeof(ndks_enable));
    if (ndks_enable == false)
        goto exit;

    //
    // NVRAM boot args are normally picked up early in the driver start routine. In this
    // case the boot arg 'ndks-debug' controls the level of debug output.
    //
    ndks_debug = 0;
    IOParseBootArgNumber("ndks-debug", &ndks_debug, sizeof(ndks_debug));

    //
    // Call the super::Start to allow the base class to also start.
    //
    ret = super::Start(provider, SUPERDISPATCH);
    if (ret != kIOReturnSuccess)
        goto exit;

    //
    // The contruct that controls serialization for method in a DriverKit driver is the
    // dispatch queue. Every NetworkingDriverKit instance will have a "Default" dispatch queue
    // it copies locally to the device instance and then passes via 'NetworkingDriverKit'
    // methods so that calls to and from NetworkingDriverKit happen in a thread-safe manner.
    //
    /// - Tag: CreateStartDispatchQueue
    ret = CopyDispatchQueue("Default", &ivars->dsQueue);
    if (ret != kIOReturnSuccess)
        goto fail;

    //
    // Create the packet pool that will be used by 'NetworkingDriverKitSample' to demonstrate
    // the packet lifecycle. The packet buffer pool is always given a name, for debugging purposes.
    // The pool options provide the details for how the NetworkingDriverKit should create the pool.
    //
    poolOptions.packetCount = 32;
    poolOptions.bufferCount = 32;
    poolOptions.bufferSize = 16*1024;
    poolOptions.maxBuffersPerPacket = 1;
    poolOptions.memorySegmentSize = 0;
    poolOptions.poolFlags = PoolFlagMapToDext;
    poolOptions.dmaSpecification.maxAddressBits = 64;
    ret = IOUserNetworkPacketBufferPool::CreateWithOptions(this, "NetworkingDriverKitSample",
        &poolOptions, &ivars->pool);
    if (ret != kIOReturnSuccess)
        goto fail;

    DLOG("==> %p (%p)", this, provider);

    //
    // The following four function set up the transmit submission queue.
    //
    /// - Tag: CreateTransmitSubmissionQueue
    ret = CreateActionTxPacketAvailable(0, &ivars->txPacketAction);
    if (ret != kIOReturnSuccess)
        goto fail;

    ret = IOUserNetworkTxSubmissionQueue::Create(
        ivars->pool, this, 8, 0, ivars->dsQueue, &ivars->txsQueue);
    if (ret != kIOReturnSuccess)
        goto fail;

    DLOG("==> %p (%p)", this, provider);

    ret = ivars->txsQueue->CopyDataQueue(&dataQueue);
    if (ret != kIOReturnSuccess)
        goto fail;

    DLOG("==> %p (%p)", this, provider);

    ret = dataQueue->SetDataAvailableHandler(ivars->txPacketAction);
    if (ret != kIOReturnSuccess)
        goto fail;

    //
    // The following three functions set up the receive queues.
    //
    /// - Tag: CreateReceiveQueues
    ret = IOUserNetworkTxCompletionQueue::Create(
        ivars->pool, this, 8, 0, ivars->dsQueue, &ivars->txcQueue);
    if (ret != kIOReturnSuccess)
        goto fail;

    DLOG("==> %p (%p)", this, provider);

    ret = IOUserNetworkRxSubmissionQueue::Create(
        ivars->pool, this, 8, 0, ivars->dsQueue, &ivars->rxsQueue);
    if (ret != kIOReturnSuccess)
        goto fail;

    DLOG("==> %p (%p)", this, provider);

    ret = IOUserNetworkRxCompletionQueue::Create(
        ivars->pool, this, 8, 0, ivars->dsQueue, &ivars->rxcQueue);
    if (ret != kIOReturnSuccess)
        goto fail;

    //
    // The following three functions demonstrate the creation of a timer that
    // mimics reception from the network while also providing an example of a timer
    // implementation.
    //
    //
    /// - Tag: CreateTimer
    ret = IOTimerDispatchSource::Create(ivars->dsQueue, &ivars->receiveTimerSource);
    if (ret != kIOReturnSuccess)
        goto fail;
    
    status = CreateActionReceiveTimer(sizeof(void *), &ivars->receiveTimer);
    if (ret != kIOReturnSuccess)
        goto fail;

    status = ivars->receiveTimerSource->SetHandler(ivars->receiveTimer);
    if (ret != kIOReturnSuccess)
        goto fail;

    //
    // Make available the networking card's Ethernet media capabilities available to Network Settings.
    //
    ret = ReportAvailableMediaTypes(mediaTable,
        sizeof(mediaTable)/sizeof(mediaTable[0]));
    if (ret != kIOReturnSuccess)
        goto fail;

    //
    // Set some basic parameters for the packets that transmission uses, specifically a hint for
    // how the hardware will use the packet.
    //
    ret = SetTxPacketHeadroom(8);
    if (ret != kIOReturnSuccess)
        goto fail;

    ret = SetTxPacketTailroom(16);
    if (ret != kIOReturnSuccess)
        goto fail;

    //
    // In the case where hardware uses a magic packet, the following call enables it.
    //
    ret = SetWakeOnMagicPacketSupport(true);
    if (ret != kIOReturnSuccess)
        goto fail;

    queues[0] = ivars->txsQueue;
    queues[1] = ivars->txcQueue;
    queues[2] = ivars->rxsQueue;
    queues[3] = ivars->rxcQueue;

    //
    // Register the interface and queues with the networking stack.
    //
    ret = RegisterEthernetInterface(macAddress, ivars->pool, queues, 4);
    if (ret != kIOReturnSuccess)
        goto fail;

    //
    // Register the NetworkingDriverkitSample as an available service.
    //
    ret = RegisterService();
    if (ret != kIOReturnSuccess)
        goto fail;
    
    status = true;

fail:
    OSSafeReleaseNULL(dataQueue);
    if (status == false)
        Stop_Impl(provider);

exit:
    DLOG("<== (%p) = 0x%08x ret = 0x%08x", provider, status, ret);

    return (ret);
}

//
// The stop routine undoes all of the items that the start routine completes.
//
kern_return_t
IMPL(NetworkingDriverKitSample, Stop)
{
    DLOG("==> (%p)", provider);

    if (ivars->receiveTimerSource) {
        ivars->receiveTimerSource->Cancel(^void(void) { OSSafeReleaseNULL(ivars->receiveTimerSource); });
    }
    OSSafeReleaseNULL(ivars->rxcQueue);
    OSSafeReleaseNULL(ivars->rxsQueue);
    OSSafeReleaseNULL(ivars->txcQueue);
    OSSafeReleaseNULL(ivars->txsQueue);
    OSSafeReleaseNULL(ivars->txPacketAction);
    OSSafeReleaseNULL(ivars->pool);
    OSSafeReleaseNULL(ivars->dsQueue);

    super::Stop(provider, SUPERDISPATCH);
    
    DLOG("<== (%p)", provider);
    return (kIOReturnSuccess);
}

//
// `SetPowerState` prepares the interface for the system going to sleep.
//
kern_return_t
IMPL(NetworkingDriverKitSample, SetPowerState)
{
    kern_return_t status;

    DLOG("==> (0x%08x)", powerstate);
    status = SetPowerState(powerstate, SUPERDISPATCH);
    DLOG("<== (0x%08x) = 0x%08x", powerstate, status);

    return (status);
}

//
// The free routine undoes eveything that the init completed.
//
void
NetworkingDriverKitSample::free( void )
{
    DLOG("==>");

    if (ivars)
        IOFree(ivars, sizeof(NetworkingDriverKitSample_IVars));

    super::free();
}

//
// `SetInterfaceEnable` enables and disables the interface connection to the network.
// It directly follows ifconfig up/down. It enables all the queues previously registered
// in the Start routine, and starts the periodic timer to mimic receive interrupts.
//
kern_return_t
IMPL(NetworkingDriverKitSample, SetInterfaceEnable)
{
    kern_return_t ret;
    uint64_t now;
    uint64_t deadline;

    DLOG("==> (%d)", isEnable);

    ret = kIOReturnSuccess;
    if (isEnable == true) {
        
        //
        // Enable all transmit and receive queues.
        //
        ret = ivars->txcQueue->SetEnable(true);
        if (ret != kIOReturnSuccess)
            goto disable;
        ret = ivars->txsQueue->SetEnable(true);
        if (ret != kIOReturnSuccess)
            goto disable;
        ret = ivars->rxcQueue->SetEnable(true);
        if (ret != kIOReturnSuccess)
            goto disable;
        ret = ivars->rxsQueue->SetEnable(true);
        if (ret != kIOReturnSuccess)
            goto disable;
        
        //
        // Start the periodic timer.
        //
        /// - Tag: StartTimer
        now = clock_gettime_nsec_np(CLOCK_UPTIME_RAW);
        deadline = now + 1000 * kMillisecondScale;
        ret = ivars->receiveTimerSource->WakeAtTime(kIOTimerClockUptimeRaw, deadline, 0);
        if (ret != kIOReturnSuccess)
            goto disable;

        //
        // Mimic bringing up the physical link.
        //
        ret = ReportLinkStatus(
                kIOUserNetworkLinkStatusActive,
                ivars->activeMediaType);
        if (ret != kIOReturnSuccess) {
            goto disable;
        }
        ivars->enable = true;
    } else {
disable:
        //
        // Stop any pending periodic timers.
        //
        ivars->receiveTimerSource->Cancel(^void(void) {});
        
        //
        // Disable all the transmit-receive queues.
        //
        ivars->txcQueue->SetEnable(false);
        ivars->txsQueue->SetEnable(false);
        ivars->rxcQueue->SetEnable(false);
        ivars->rxsQueue->SetEnable(false);
        ivars->enable = false;
    }

exit:
    DLOG("==> (%d) = 0x%08x", isEnable, ret);

    return (ret);
}

static const uint8_t echoRequest[] =
{
    0x10, 0x22, 0x33, 0x44 ,0x55, 0x66, 0x10, 0xdd,
    0xb1, 0xa2, 0xee, 0xeb, 0x08, 0x00, 0x45, 0x00,
    0x00, 0x54, 0x82, 0x61, 0x00, 0x00, 0x40, 0x01,
    0x80, 0xa3, 0x11, 0xc0, 0xaa, 0x13, 0x11, 0xc0,
    0xaa, 0x11, 0x08, 0x00, 0xe8, 0x12, 0x12, 0x02,
    0x00, 0x00, 0x5b, 0xfd, 0xd3, 0xbe, 0x00, 0x02,
    0xe3, 0x29, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d,
    0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15,
    0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d,
    0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25,
    0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d,
    0x2e, 0x2f, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35,
    0x36, 0x37
};

//
// The system calls this `TxPacketAvailable` method the stack has placed packets
// on the transmit submission queue.
//
void
IMPL(NetworkingDriverKitSample, TxPacketAvailable)
{
    IOUserNetworkPacket *packets[8];
    IOUserNetworkPacket *packet;
    uint32_t dequeueCount = 0;
    uint64_t dataOffset;
    uint8_t linkHeaderLength;
    uint8_t *dataAddr;
    kern_return_t ret;
    int i;

    DLOG("==> (%p)", action);

    /// - Tag: TransmitPackets
    dequeueCount = ivars->txsQueue->DequeuePackets(packets, 8);

    linkHeaderLength = 0;
    
    if (dequeueCount) {
        for (i = 0; i < dequeueCount; i++) {
            packet = packets[i];

            DLOG("dequeue - TX packet[%d] = %p", i, packet);

            dataAddr = (uint8_t *)packet->getDataVirtualAddress();
            dataOffset = packet->getDataOffset();
            
            ret = packet->GetLinkHeaderLength(&linkHeaderLength);
            
            DLOG("dataAddr = %p dataOffset = %llu linkHeaderLength = %d", dataAddr, dataOffset, linkHeaderLength);

            ret = ivars->txcQueue->EnqueuePacket(packet);
            if (ret != kIOReturnSuccess) {
                ivars->pool->DeallocatePacket(packet);
                LOG("Returning Tx Packet failed just return to pool\n");
            }
        }
    }
    DLOG("<== (%p)", action);
}

//
// `ReceiveTimer` mimics a receive interrupt so the sample can pass a fake icmp
// request packet for reception. The receive submission queue provides the buffer to copy
// the packet to, then passes the packet to the receive completion queue.
//
void
IMPL(NetworkingDriverKitSample, ReceiveTimer)
{
    IOReturn ret;
    IOUserNetworkPacket *packets[8];
    IOUserNetworkPacket *packet;
    uint32_t dequeueCount;
    void *pktBuffer;
    uint8_t *dataAddr;
    uint64_t dataOffset;
    uint8_t linkHeaderLength;
    bool good_packet;
    uint64_t now;
    uint64_t deadline;
    int i;

    DLOG("==> (%p, 0x%016llx)", action, time);

    /// - Tag: ReceivePackets
    dequeueCount = ivars->rxsQueue->DequeuePackets(packets, 8);

    linkHeaderLength = 0;
    for (i = 0; i < dequeueCount; i++) {
        packet = packets[i];
        good_packet = true;
        dataAddr = (uint8_t *)packet->getDataVirtualAddress();
        dataOffset = packet->getDataOffset();
        
        DLOG("dataAddr = %p dataOffset = %llu", dataAddr, dataOffset);
        
        pktBuffer = (decltype(pktBuffer))(uintptr_t)(dataAddr + dataOffset);
        
        bcopy(echoRequest, pktBuffer, sizeof(echoRequest));

        ret = packet->setDataOffset(dataOffset);
        good_packet &= (ret == kIOReturnSuccess);

        ret = packet->SetLinkHeaderLength(linkHeaderLength);
        good_packet &= (ret == kIOReturnSuccess);

        ret = packet->setDataLength(sizeof(echoRequest));
        good_packet &= (ret == kIOReturnSuccess);

        if (good_packet) {
            DLOG("enqueue - packet[%d] = %p", i, packet);

            ret = ivars->rxcQueue->EnqueuePacket(packet);
            if (ret != kIOReturnSuccess) {
                ivars->pool->DeallocatePacket(packet);
                LOG("Enqueue failed dropping pkt\n");
            }
        } else {
            ivars->pool->DeallocatePacket(packet);
            LOG("Packet setup failed dropping pkt\n");
        }
    }
    
    now = clock_gettime_nsec_np(CLOCK_UPTIME_RAW);
    deadline = now + 5ULL * kSecondScale;
    ret = ivars->receiveTimerSource->WakeAtTime(kIOTimerClockUptimeRaw, deadline, 0);
    if (ret != kIOReturnSuccess) {
        DLOG("error setting interrupt read timer 0x%08x\n", ret);
    }

    DLOG("<== (%p, 0x%016llx)", action, time);
}

//
// The following collection of functions demostrate when these functions
// are called, and what functions may need an override in a real-world
// NetworkingDriverKit driver.
//
// Normally, a driver uses `SetPromiscuousModeEnable` to open the device network
// packet filter to allow all packets to be received.
//
kern_return_t
IMPL(NetworkingDriverKitSample,SetPromiscuousModeEnable)
{
    IOReturn status;
    
    DLOG("==> (%d)", enable);
    
    status = kIOReturnSuccess;

    DLOG("<== (%d) = 0x%08x", enable, status);
    return (status);
}

//
// Normally, a driver uses `SetWakeOnMagicPacketEnable` to program the hardware
// to support the Wake on Magic packet.
//
kern_return_t
IMPL(NetworkingDriverKitSample, SetWakeOnMagicPacketEnable)
{
    kern_return_t status;
    
    DLOG("==> (%d)", enable);
    
    status = kIOReturnSuccess;

    DLOG("<== (%d) = 0x%08x", enable, status);
    return (status);
}

//
// Normally, a driver uses `SetMTU` to program the hardware maximum transfer unit,
// if special programming is required.
//
kern_return_t
IMPL(NetworkingDriverKitSample, SetMTU)
{
    IOReturn status;
    
    DLOG("==> (%d)", mtu);
    
    status = kIOReturnSuccess;

    DLOG("<== (%d) = 0x%08x", mtu, status);
    return (status);
}

//
// The `GetMaxTransferUnit` function allows a driver to let the networking stack know
// the maximun transfer unit that the networking hardware is capable of.
//
kern_return_t
IMPL(NetworkingDriverKitSample, GetMaxTransferUnit)
{
    DLOG("==> ()");

    *mtu = 9000;
    DLOG("<== () = %d", *mtu);

    return (kIOReturnSuccess);
}

//
// Normally, a driver uses `SetHardwareAssists` to program the hardware assists,
// if special programming is required.
//
kern_return_t
IMPL(NetworkingDriverKitSample, SetHardwareAssists)
{
    IOReturn status;
    
    DLOG("==> (%d)", hardwareAssists);
    
    status = kIOReturnSuccess;

    DLOG("<== (%d) = 0x%08x", hardwareAssists, status);
    return (status);
}

//
// The `GetHardwareAssists` function allows a driver to let the networking stack know the
// hardware assist that the networking hardware is capable of.
//
kern_return_t
IMPL(NetworkingDriverKitSample, GetHardwareAssists)
{
    DLOG("==> ()");

    *hardwareAssists = 0;
    
    DLOG("<== () = %d", *hardwareAssists);

    return (kIOReturnSuccess);
}

//
// The `SetMulticastAddresses` function allows the networking stack to share with the
// driver the array of multicast addresses that should be programmed into the hardware
// networking packet filter.
//
kern_return_t
IMPL(NetworkingDriverKitSample, SetMulticastAddresses)
{
    IOReturn status;
    DLOG("==> (%p, %d)", addresses, count);

    for (uint32_t i = 0; i < count; i++) {
        LOG("MC[%u]: %02x:%02x:%02x:%02x:%02x:%02x\n", i,
            addresses[i].octet[0], addresses[i].octet[1],
            addresses[i].octet[2], addresses[i].octet[3],
            addresses[i].octet[4], addresses[i].octet[5]);
    }

    status = kIOReturnSuccess;
    
    DLOG("==> (%p, %d) = 0x%08x", addresses, count, status);

    return (status);
}

//
// The `SetAllMulticastModeEnable` function allows the networking stack to share with the
// driver the array of multicast adddresses that should be programmed into the hardware
// networking packet filter.
//
kern_return_t
IMPL(NetworkingDriverKitSample, SetAllMulticastModeEnable)
{
    IOReturn status;
    
    DLOG("==> (%d)", enable);
    
    status = kIOReturnSuccess;

    DLOG("<== (%d) = 0x%08x", enable, status);
    return (status);
}

//
// The `SelectMediaType` function allows the networking stack to share with the
// driver the networking media that should be used. In this sample driver it will follow
// the Manual Media setting set in Network Preferences.
//
kern_return_t
IMPL(NetworkingDriverKitSample, SelectMediaType)
{
    IOReturn status;

    DLOG("==> (0x%08x)", mediaType);

    LOG("NetworkingDriverKitSample::%s(%x)\n", __FUNCTION__, mediaType);

    status = kIOReturnSuccess;
    if (ivars->chosenMediaType != mediaType) {
        ivars->chosenMediaType = mediaType;
        
        if (ivars->chosenMediaType == kIOUserNetworkMediaEthernetAuto)
            ivars->activeMediaType = kIOUserNetworkMediaEthernet1000BaseT;
        else
            ivars->activeMediaType = ivars->chosenMediaType;

        if (ivars->enable) {
            status = ReportLinkStatus(
                        kIOUserNetworkLinkStatusActive,
                        ivars->activeMediaType);
        }
    }

    DLOG("<== (0x%08x) = 0x%08x", mediaType, status);

    return (status);
}
