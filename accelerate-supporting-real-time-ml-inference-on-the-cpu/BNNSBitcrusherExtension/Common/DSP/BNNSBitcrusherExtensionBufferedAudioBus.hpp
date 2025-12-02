/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The BNNS bitcrusher `BufferedAudioBus` utility class header.
*/


#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>

#include <algorithm>

//MARK:- BufferedAudioBus Utility Class
// Utility classes to manage audio formats and buffers for an audio unit implementation's input and output audio buses.

// A reusable non-Objective-C class, accessible from the render thread.
struct BufferedAudioBus {
    AUAudioUnitBus* bus = nullptr;
    AUAudioFrameCount maxFrames = 0;
    
    AVAudioPCMBuffer* pcmBuffer = nullptr;
    
    AudioBufferList const* originalAudioBufferList = nullptr;
    AudioBufferList* mutableAudioBufferList = nullptr;

    void init(AVAudioFormat* defaultFormat, AVAudioChannelCount maxChannels) {
        maxFrames = 0;
        pcmBuffer = nullptr;
        originalAudioBufferList = nullptr;
        mutableAudioBufferList = nullptr;

        bus = [[AUAudioUnitBus alloc] initWithFormat:defaultFormat error:nil];

        bus.maximumChannelCount = maxChannels;
    }

    void allocateRenderResources(AUAudioFrameCount inMaxFrames) {
        maxFrames = inMaxFrames;

        pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:bus.format frameCapacity: maxFrames];

        originalAudioBufferList = pcmBuffer.audioBufferList;
        mutableAudioBufferList = pcmBuffer.mutableAudioBufferList;
    }
    
    void deallocateRenderResources() {
        pcmBuffer = nullptr;
        originalAudioBufferList = nullptr;
        mutableAudioBufferList = nullptr;
    }
};

// MARK:-  BufferedOutputBus: BufferedAudioBus
// MARK: prepareOutputBufferList()
/*
 `BufferedOutputBus`
 
 This class provides a `prepareOutputBufferList` method to copy the internal buffer pointers
 to the output buffer list in case the client passes in null buffer pointers.
 */
struct BufferedOutputBus: BufferedAudioBus {
    void prepareOutputBufferList(AudioBufferList* outBufferList, AVAudioFrameCount frameCount, bool zeroFill) {
        UInt32 byteSize = frameCount * sizeof(float);
        for (UInt32 i = 0; i < outBufferList->mNumberBuffers; ++i) {
            outBufferList->mBuffers[i].mNumberChannels = originalAudioBufferList->mBuffers[i].mNumberChannels;
            outBufferList->mBuffers[i].mDataByteSize = byteSize;
            if (outBufferList->mBuffers[i].mData == nullptr) {
                outBufferList->mBuffers[i].mData = originalAudioBufferList->mBuffers[i].mData;
            }
            if (zeroFill) {
                memset(outBufferList->mBuffers[i].mData, 0, byteSize);
            }
        }
    }
};

// MARK: -  BufferedInputBus: BufferedAudioBus
// MARK: pullInput()
// MARK: prepareInputBufferList()
/*
 `BufferedInputBus`
 
 This class manages a buffer into which an audio unit with input buses can
 pull its input data.
 */
struct BufferedInputBus : BufferedAudioBus {
    /*
     Gets the input data for this input by preparing the input buffer list and pulling
     the `pullInputBlock`.
     */
    AUAudioUnitStatus pullInput(AudioUnitRenderActionFlags *actionFlags,
                                AudioTimeStamp const* timestamp,
                                AVAudioFrameCount frameCount,
                                NSInteger inputBusNumber,
                                AURenderPullInputBlock __unsafe_unretained pullInputBlock) {
        if (pullInputBlock == nullptr) {
            return kAudioUnitErr_NoConnection;
        }
        
        /*
         Important:
         The audio unit needs to supply valid buffers in `(inputData->mBuffers[x].mData)` and `mDataByteSize`.
         `mDataByteSize` needs to be consistent with `frameCount`.

         `AURenderPullInputBlock` may provide input in those specified buffers, or it may replace
         the `mData` pointers with pointers to memory that it owns and ensures it remains valid
         until the next render cycle.

         See `prepareInputBufferList()`.
         */

        prepareInputBufferList(frameCount);

        return pullInputBlock(actionFlags, timestamp, frameCount, inputBusNumber, mutableAudioBufferList);
    }
    
    /*
     `prepareInputBufferList` populates the `mutableAudioBufferList` with the data
     pointers from the `originalAudioBufferList`.
     
     The upstream audio unit may overwrite these with its own pointers, so the system needs to call this function for each
     render cycle to reset them.
     */
    void prepareInputBufferList(UInt32 frameCount) {
        UInt32 byteSize = std::min(frameCount, maxFrames) * sizeof(float);
        mutableAudioBufferList->mNumberBuffers = originalAudioBufferList->mNumberBuffers;

        for (UInt32 i = 0; i < originalAudioBufferList->mNumberBuffers; ++i) {
            mutableAudioBufferList->mBuffers[i].mNumberChannels = originalAudioBufferList->mBuffers[i].mNumberChannels;
            mutableAudioBufferList->mBuffers[i].mData = originalAudioBufferList->mBuffers[i].mData;
            mutableAudioBufferList->mBuffers[i].mDataByteSize = byteSize;
        }
    }
};
