/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An Objective-C adapter for low-level MIDI functions.
*/

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

NS_ASSUME_NONNULL_BEGIN

@interface MIDIAdapter : NSObject

/// Initialize a MIDI adapter with optional logging.
/// @param queueEnabled Enable the queue for logging data to the screen.
- (instancetype)initWithLogging:(BOOL)queueEnabled;

/// Create a Core MIDI destination.
/// @param client A reference to the MIDI client.
/// @param name The name of the destination to create.
/// @param protocol The MIDI protocol to use, MIDI 1 or MIDI 2.
/// @param outDest A reference to the new destination.
-(OSStatus)createMIDIDestination:(MIDIClientRef)client named:(CFStringRef)name protocol:(MIDIProtocolID)protocol dest:(MIDIEndpointRef *)outDest;

/// Pop a message from the MIDI queue from the main thread (if the adapter initializes with one, or else the system doesn't call the callback).
/// @param callback A block to call when a MIDI message successfully pops.
-(void)popDestinationMessages:(void (^)(const MIDIEventPacket))callback;

/// Open a Core MIDI port.
/// @param client A reference to the MIDI client.
/// @param name The name of the port to create.
/// @param outPort A reference to the new MIDI port.
-(OSStatus)openMIDIPort:(MIDIClientRef)client named:(CFStringRef)name port:(MIDIPortRef *)outPort;

/// Send a MIDI-1UP message.
/// @param message A Universal MIDI Packet with a 32-bit length.
/// @param port A reference to the output MIDI port.
/// @param destination The Core MIDI destination to send the message to.
-(OSStatus)sendMIDI1UPMessage:(MIDIMessage_32)message port:(MIDIPortRef)port destination:(MIDIEndpointRef)destination;

/// Send a MIDI 2 message.
/// @param message A Universal MIDI Packet with a 64-bit length.
/// @param port A reference to the output MIDI port.
/// @param destination The Core MIDI destination to send the message to.
-(OSStatus)sendMIDI2Message:(MIDIMessage_64)message port:(MIDIPortRef)port destination:(MIDIEndpointRef)destination;
@end

NS_ASSUME_NONNULL_END
