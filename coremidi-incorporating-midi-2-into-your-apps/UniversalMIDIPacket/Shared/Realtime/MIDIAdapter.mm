/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An Objective-C adapter for low-level MIDI functions.
*/

#import "MIDIAdapter.h"
#import "SingleProducerSingleConsumerQueue.hpp"

typedef SingleProducerSingleConsumerQueue<MIDIEventPacket> MIDIMessageFIFO;

@implementation MIDIAdapter {
    std::unique_ptr<MIDIMessageFIFO> messageQueue;
}

- (instancetype)initWithLogging:(BOOL)queueEnabled {
    self = [super init];
    if (self) {
        if (queueEnabled) {
            messageQueue = std::make_unique<MIDIMessageFIFO>(64);
        }
    }
    return self;
}

// MARK: - Core MIDI

-(OSStatus)createMIDIDestination:(MIDIClientRef)client named:(CFStringRef)name protocol:(MIDIProtocolID)protocol dest:(MIDIEndpointRef *)outDest {
    __block MIDIMessageFIFO *msgQueue = messageQueue.get();
    const auto status = MIDIDestinationCreateWithProtocol(client, name, protocol, outDest, ^(const MIDIEventList * _Nonnull evtlist, void * _Nullable srcConnRefCon) {
        
        if (evtlist->numPackets > 0 && msgQueue) {
            auto pkt = &evtlist->packet[0];

            for (int i = 0; i < evtlist->numPackets; ++i) {
                if (!msgQueue->push(evtlist->packet[i])) {
                    msgQueue->push(evtlist->packet[i]);
                }
                pkt = MIDIEventPacketNext(pkt);
            }
        }
    });
    return status;
}

-(void)popDestinationMessages:(void (^)(const MIDIEventPacket))callback {
    if (!messageQueue)
        return;

    while (const auto message = messageQueue->pop()) {
        callback(*message);
    }
}

-(OSStatus)openMIDIPort:(MIDIClientRef)client named:(CFStringRef)name port:(MIDIPortRef *)outPort {
    return MIDIOutputPortCreate(client, name, outPort);
}

-(OSStatus)sendMIDI1UPMessage:(MIDIMessage_32)message port:(MIDIPortRef)port destination:(MIDIEndpointRef)destination {
    MIDIEventList eventList = {};
    MIDIEventPacket *packet = MIDIEventListInit(&eventList, kMIDIProtocol_1_0);
    packet = MIDIEventListAdd(&eventList, sizeof(MIDIEventList), packet, 0, 1, (UInt32 *)&message);
    return MIDISendEventList(port, destination, &eventList);
}

-(OSStatus)sendMIDI2Message:(MIDIMessage_64)message port:(MIDIPortRef)port destination:(MIDIEndpointRef)destination {
    MIDIEventList eventList = {};
    MIDIEventPacket *packet = MIDIEventListInit(&eventList, kMIDIProtocol_2_0);
    packet = MIDIEventListAdd(&eventList, sizeof(MIDIEventList), packet, 0, 2, (UInt32 *)&message);
    return MIDISendEventList(port, destination, &eventList);
}

@end
