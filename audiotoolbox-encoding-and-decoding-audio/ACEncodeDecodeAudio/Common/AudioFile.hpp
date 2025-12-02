/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class to manage the audio file handling for the app.
*/

#pragma once

#include <AudioToolbox/AudioToolbox.h>
#include <optional>
#include <string>

class AudioFile {
public:
	~AudioFile();
	AudioFile(const AudioFile&) = delete;
	AudioFile(AudioFile&&);
	AudioFile& operator=(const AudioFile&) = delete;
	AudioFile& operator=(AudioFile&&);

	static AudioFile Open(const char* path);
	static AudioFile Create(
		const char* path, AudioFileTypeID fileType, const AudioStreamBasicDescription& format);
	void ReadPackets(UInt32& ioNumBytes, AudioStreamPacketDescription* outPacketDescriptions,
		UInt32& ioNumPackets, void* outBuffer);
	UInt32 WritePackets(UInt32 inNumBytes, const AudioStreamPacketDescription* inPacketDescriptions,
		UInt32 inNumPackets, const void* inBuffer);
	size_t GetProperty(AudioFilePropertyID inPropertyID, size_t inDataSize, void* outPropertyData);
	std::optional<size_t> GetPropertySize(AudioFilePropertyID inPropertyID);
	void SetProperty(
		AudioFilePropertyID inPropertyID, size_t inDataSize, const void* inPropertyData);
	SInt64 NextPacket() const { return mNextPacket; }

    std::string GetFilePath();
    
private:
	AudioFile(AudioFileID audioFileID, std::string path);
	void Dispose();

	AudioFileID mAudioFileID;
	std::string mPath;
	bool mValid;
	SInt64 mNextPacket;
};
