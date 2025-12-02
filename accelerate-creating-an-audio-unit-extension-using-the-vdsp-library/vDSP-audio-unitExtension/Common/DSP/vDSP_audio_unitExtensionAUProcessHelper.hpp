/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The vDSP audio unit header.
*/

#pragma once

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#include <vector>
#include "vDSP_audio_unitExtensionDSPKernel.hpp"

//MARK:- AUProcessHelper Utility Class
class AUProcessHelper
{
public:
    AUProcessHelper(vDSP_audio_unitExtensionDSPKernel& kernel, UInt32 inputChannelCount, UInt32 outputChannelCount)
    : mKernel{kernel},
    mInputBuffers(inputChannelCount),
    mOutputBuffers(outputChannelCount) {
    }

    /**
     This function handles the event list processing and rendering loop for you.
     Call it inside your internalRenderBlock.
     */
    void processWithEvents(AudioBufferList* inBufferList, AudioBufferList* outBufferList, AudioTimeStamp const *timestamp, AUAudioFrameCount frameCount, AURenderEvent const *events) {

        AUEventSampleTime now = AUEventSampleTime(timestamp->mSampleTime);
        AUAudioFrameCount framesRemaining = frameCount;
        AURenderEvent const *nextEvent = events; // `events` is a linked list. At the beginning, the `nextEvent` is the first event.

        auto callProcess = [this] (AudioBufferList* inBufferListPtr, AudioBufferList* outBufferListPtr, AUEventSampleTime now, AUAudioFrameCount frameCount, AUAudioFrameCount const frameOffset) {
            for (int channel = 0; channel < inBufferListPtr->mNumberBuffers; ++channel) {
                mInputBuffers[channel] = (const float*)inBufferListPtr->mBuffers[channel].mData  + frameOffset;
            }
            
            for (int channel = 0; channel < outBufferListPtr->mNumberBuffers; ++channel) {
                mOutputBuffers[channel] = (float*)outBufferListPtr->mBuffers[channel].mData + frameOffset;
            }

            mKernel.process(mInputBuffers, mOutputBuffers, now, frameCount);
        };
        
        while (framesRemaining > 0) {
            // If there are no more events, process the entire remaining segment and exit.
            if (nextEvent == nullptr) {
                AUAudioFrameCount const frameOffset = frameCount - framesRemaining;
                callProcess(inBufferList, outBufferList, now, framesRemaining, frameOffset);
                return;
            }

            // Start late events late.
            auto timeZero = AUEventSampleTime(0);
            auto headEventTime = nextEvent->head.eventSampleTime;
            AUAudioFrameCount framesThisSegment = AUAudioFrameCount(std::max(timeZero, headEventTime - now));

            // Compute everything before the next event.
            if (framesThisSegment > 0) {
                AUAudioFrameCount const frameOffset = frameCount - framesRemaining;

                callProcess(inBufferList, outBufferList, now, framesThisSegment, frameOffset);

                // Advance frames.
                framesRemaining -= framesThisSegment;

                // Advance time.
                now += AUEventSampleTime(framesThisSegment);
            }

            nextEvent = performAllSimultaneousEvents(now, nextEvent);
        }
    }

    AURenderEvent const * performAllSimultaneousEvents(AUEventSampleTime now, AURenderEvent const *event) {
        do {
            mKernel.handleOneEvent(now, event);
            
            // Go to next event.
            event = event->head.next;

            // While event is not null and is simultaneous (or late).
        } while (event && event->head.eventSampleTime <= now);
        return event;
    }
private:
    vDSP_audio_unitExtensionDSPKernel& mKernel;
    std::vector<const float*> mInputBuffers;
    std::vector<float*> mOutputBuffers;
};
