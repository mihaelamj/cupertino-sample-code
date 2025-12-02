/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class to manage the audio conversion the app does.
*/

#include "AudioConverter.hpp"
#include "AudioToolboxError.hpp"

#include <sstream>

AudioConverter::~AudioConverter() { Dispose(); }

AudioConverter::AudioConverter(AudioConverter&& other)
	: mAudioConverterRef(other.mAudioConverterRef), mValid(other.mValid)
{
	other.mValid = false;
}

AudioConverter& AudioConverter::operator=(AudioConverter&& other)
{
	if (&other != this) {
		Dispose();
		std::swap(mValid, other.mValid);
		if (mValid) {
			mAudioConverterRef = other.mAudioConverterRef;
		}
	}
	return *this;
}

AudioConverter::AudioConverter(const AudioStreamBasicDescription& inSourceFormat,
	const AudioStreamBasicDescription& inDestinationFormat)
	: mAudioConverterRef(NULL), mValid(false)
{
	const OSStatus err =
		AudioConverterNew(&inSourceFormat, &inDestinationFormat, &mAudioConverterRef);
	if (err == noErr) {
		mValid = true;
	} else {
		throw AudioToolboxError("Unable to create an audio converter!", err);
	}
}

void AudioConverter::FillComplexBuffer(AudioConverterComplexInputDataProc inInputDataProc,
	void* inInputDataProcUserData, UInt32& ioOutputDataPacketSize, AudioBufferList& outOutputData,
	AudioStreamPacketDescription* outPacketDescription)
{
	const OSStatus err = AudioConverterFillComplexBuffer(mAudioConverterRef, inInputDataProc,
		inInputDataProcUserData, &ioOutputDataPacketSize, &outOutputData, outPacketDescription);
	if (err != noErr) {
		throw AudioToolboxError("Unable to convert audio!", err);
	}
}

size_t AudioConverter::GetProperty(
	AudioConverterPropertyID inPropertyID, size_t inDataSize, void* outPropertyData)
{
	UInt32 dataSize = (UInt32)inDataSize;
	const OSStatus err =
		AudioConverterGetProperty(mAudioConverterRef, inPropertyID, &dataSize, outPropertyData);
	if (err != noErr) {
		std::ostringstream buf;
		buf << "unable to get the property " << inPropertyID << " from the audio converter";
		throw AudioToolboxError(buf.str(), err);
	}
	return (size_t)dataSize;
}

size_t AudioConverter::GetPropertySize(AudioConverterPropertyID inPropertyID)
{
	UInt32 size;
	Boolean isWritable;
	const OSStatus err =
		AudioConverterGetPropertyInfo(mAudioConverterRef, inPropertyID, &size, &isWritable);
	if (err != noErr) {
		std::ostringstream buf;
		buf << "unable to get the property " << inPropertyID << " info from the audio converter";
		throw AudioToolboxError(buf.str(), err);
	}
	return (size_t)size;
}

void AudioConverter::SetProperty(
	AudioConverterPropertyID inPropertyID, size_t inDataSize, const void* inPropertyData)
{
	const OSStatus err = AudioConverterSetProperty(
		mAudioConverterRef, inPropertyID, (UInt32)inDataSize, inPropertyData);
	if (err != noErr) {
		std::ostringstream buf;
		buf << "unable to set the property " << inPropertyID << " on the audio converter";
		throw AudioToolboxError(buf.str(), err);
	}
}

void AudioConverter::Dispose()
{
	if (mValid) {
		AudioConverterDispose(mAudioConverterRef);
	}
}
