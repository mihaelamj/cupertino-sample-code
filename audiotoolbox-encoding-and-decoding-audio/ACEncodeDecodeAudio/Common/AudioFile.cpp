/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class to manage the audio file handling for the app.
*/

#include "AudioFile.hpp"
#include "AudioToolboxError.hpp"

#include <sstream>

AudioFile::~AudioFile() { Dispose(); }

AudioFile::AudioFile(AudioFile&& other)
	: mAudioFileID(other.mAudioFileID), mPath(std::move(other.mPath)), mValid(other.mValid),
	  mNextPacket(other.mNextPacket)
{
	other.mValid = false;
}

AudioFile& AudioFile::operator=(AudioFile&& other)
{
	if (&other != this) {
		Dispose();
		std::swap(mValid, other.mValid);
		if (mValid) {
			mAudioFileID = other.mAudioFileID;
			mPath = std::move(other.mPath);
			mNextPacket = other.mNextPacket;
		}
	}
	return *this;
}

AudioFile AudioFile::Open(const char* path)
{
	const CFURLRef inputFileURL = CFURLCreateFromFileSystemRepresentation(
		kCFAllocatorDefault, (UInt8*)path, strlen(path), false);
	AudioFileID fileID;
	const OSStatus err = AudioFileOpenURL(inputFileURL, kAudioFileReadPermission, 0, &fileID);
	CFRelease(inputFileURL);
	if (err != noErr) {
		std::ostringstream buf;
		buf << "unable to open the input file \"" << path << "\"";
		throw AudioToolboxError(buf.str(), err);
	}
	return AudioFile(fileID, path);
}

AudioFile AudioFile::Create(
	const char* path, AudioFileTypeID fileType, const AudioStreamBasicDescription& format)
{
	const CFURLRef outputFileURL = CFURLCreateFromFileSystemRepresentation(
		kCFAllocatorDefault, (UInt8*)path, strlen(path), false);
	AudioFileID fileID;
	const OSStatus err = AudioFileCreateWithURL(
		outputFileURL, fileType, &format, kAudioFileFlags_EraseFile, &fileID);
	CFRelease(outputFileURL);
	if (err != noErr) {
		std::ostringstream buf;
		buf << "unable to create the output file \"" << path << "\"";
		throw AudioToolboxError(buf.str(), err);
	}
	return AudioFile(fileID, path);
}

void AudioFile::ReadPackets(UInt32& ioNumBytes, AudioStreamPacketDescription* outPacketDescriptions,
	UInt32& ioNumPackets, void* outBuffer)
{
	const OSStatus err = AudioFileReadPacketData(mAudioFileID, false, &ioNumBytes,
		outPacketDescriptions, mNextPacket, &ioNumPackets, outBuffer);
	if (err == noErr) {
		mNextPacket += ioNumPackets;
	} else {
		std::ostringstream buf;
		buf << "unable to read packets from the file \"" << mPath << "\"";
		throw AudioToolboxError(buf.str(), err);
	}
}

UInt32 AudioFile::WritePackets(UInt32 inNumBytes,
	const AudioStreamPacketDescription* inPacketDescriptions, UInt32 inNumPackets,
	const void* inBuffer)
{
	const OSStatus err = AudioFileWritePackets(mAudioFileID, false, inNumBytes,
		inPacketDescriptions, mNextPacket, &inNumPackets, inBuffer);
	if (err == noErr) {
		mNextPacket += inNumPackets;
	} else {
		std::ostringstream buf;
		buf << "unable to write packets to the file \"" << mPath << "\"";
		throw AudioToolboxError(buf.str(), err);
	}
	return inNumPackets;
}

size_t AudioFile::GetProperty(
	AudioFilePropertyID inPropertyID, size_t inDataSize, void* outPropertyData)
{
	UInt32 dataSize = (UInt32)inDataSize;
	const OSStatus err =
		AudioFileGetProperty(mAudioFileID, inPropertyID, &dataSize, outPropertyData);
	if (err != noErr) {
		std::ostringstream buf;
		buf << "unable to get the property " << inPropertyID << " of the file \"" << mPath << "\"";
		throw AudioToolboxError(buf.str(), err);
	}
	return (size_t)dataSize;
}

std::optional<size_t> AudioFile::GetPropertySize(AudioFilePropertyID inPropertyID)
{
	UInt32 size;
	UInt32 isWritable;
	const OSStatus err = AudioFileGetPropertyInfo(mAudioFileID, inPropertyID, &size, &isWritable);
	if (err != noErr) {
		if (err == kAudioFileUnsupportedPropertyError) {
			return std::nullopt;
		} else {
			std::ostringstream buf;
			buf << "unable to get the property " << inPropertyID << " info of the file \"" << mPath << "\"";
			throw AudioToolboxError(buf.str(), err);
		}
	}
	return (size_t)size;
}

void AudioFile::SetProperty(
	AudioFilePropertyID inPropertyID, size_t inDataSize, const void* inPropertyData)
{
	const OSStatus err =
		AudioFileSetProperty(mAudioFileID, inPropertyID, (UInt32)inDataSize, inPropertyData);
	if (err != noErr) {
		std::ostringstream buf;
		buf << "unable to set the property " << inPropertyID << " of the file \"" << mPath << "\"";
		throw AudioToolboxError(buf.str(), err);
	}
}

AudioFile::AudioFile(AudioFileID audioFileID, std::string path)
	: mAudioFileID(audioFileID), mPath(std::move(path)), mValid(true), mNextPacket(0)
{
}

std::string AudioFile::GetFilePath()
{
    return mPath;
}

void AudioFile::Dispose()
{
	if (mValid) {
		AudioFileClose(mAudioFileID);
	}
}
