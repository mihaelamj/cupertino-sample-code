/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class to help with the audio conversion the app does.
*/

#pragma once

#include <AudioToolbox/AudioToolbox.h>
#include <string>

class AudioConverter {
public:
	~AudioConverter();
	AudioConverter(const AudioConverter&) = delete;
	AudioConverter(AudioConverter&&);
	AudioConverter& operator=(const AudioConverter&) = delete;
	AudioConverter& operator=(AudioConverter&&);

	AudioConverter(const AudioStreamBasicDescription& inSourceFormat,
		const AudioStreamBasicDescription& inDestinationFormat);
	void FillComplexBuffer(AudioConverterComplexInputDataProc inInputDataProc,
		void* inInputDataProcUserData, UInt32& ioOutputDataPacketSize,
		AudioBufferList& outOutputData, AudioStreamPacketDescription* outPacketDescription);
	size_t GetProperty(
		AudioConverterPropertyID inPropertyID, size_t inDataSize, void* outPropertyData);
	size_t GetPropertySize(AudioConverterPropertyID inPropertyID);
	void SetProperty(
		AudioConverterPropertyID inPropertyID, size_t inDataSize, const void* inPropertyData);

private:
	void Dispose();

	AudioConverterRef mAudioConverterRef;
	bool mValid;
};
