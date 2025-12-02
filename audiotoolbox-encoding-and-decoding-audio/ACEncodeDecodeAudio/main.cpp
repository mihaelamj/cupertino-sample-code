/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A sample that encodes and decodes audio files.
*/

#include <AudioToolbox/AudioToolbox.h>

#include "AudioConverter.hpp"
#include "AudioFile.hpp"
#include "AudioToolboxError.hpp"

#include <iostream>
#include <stdlib.h>
#include <vector>

class InputContext {
public:
	InputContext(AudioFile inputFile, AudioStreamBasicDescription inputDescription,
		UInt32 maxInputPacketSize, bool inputUsesPacketDescriptions)
		: mInputFile(std::move(inputFile)), mInputDescription(std::move(inputDescription)),
		  mMaxInputPacketSize(maxInputPacketSize),
		  mInputUsesPacketDescriptions(inputUsesPacketDescriptions)
	{
	}

	SInt64 NumPacketsRead() const { return mInputFile.NextPacket(); }

	static OSStatus InputDataProc(AudioConverterRef inAudioConverter, UInt32* ioNumberDataPackets,
		AudioBufferList* ioData, AudioStreamPacketDescription** outDataPacketDescription,
		void* inUserData)
	{
		InputContext& self = *(InputContext*)inUserData;

		// Set up the input buffer.
		self.mInputBuffer.resize((size_t)(*ioNumberDataPackets * self.mMaxInputPacketSize));

		// If the input uses packet descriptions, set up the buffer for that,
		// and provide access to it for the caller by storing a pointer to it
		// in the `outDataPacketDescription` provided.
		if (self.mInputUsesPacketDescriptions) {
			self.mPacketDescriptions.resize((size_t)*ioNumberDataPackets);
			*outDataPacketDescription = self.mPacketDescriptions.data();
		}

		// Fill in the AudioBufferList to refer to the packet buffer.
		ioData->mNumberBuffers = 1;
		ioData->mBuffers[0].mNumberChannels = self.mInputDescription.mChannelsPerFrame;
		ioData->mBuffers[0].mDataByteSize = (UInt32)self.mInputBuffer.size();
		ioData->mBuffers[0].mData = self.mInputBuffer.data();

		// Read packets from the file into the buffer, along with packet descriptions, if any exist.
		try {
			self.mInputFile.ReadPackets(ioData->mBuffers[0].mDataByteSize,
										self.mInputUsesPacketDescriptions ? self.mPacketDescriptions.data() : NULL,
										*ioNumberDataPackets,
										ioData->mBuffers[0].mData);
		} catch (AudioToolboxError err) {
			std::cerr << "Encountered an error while reading packets: " << err.what() << std::endl;
			return err.status;
		}
		return noErr;
	}

private:
	AudioFile mInputFile;
	AudioStreamBasicDescription mInputDescription;
	std::vector<uint8_t> mInputBuffer;
	std::vector<AudioStreamPacketDescription> mPacketDescriptions;
	const UInt32 mMaxInputPacketSize;
	const bool mInputUsesPacketDescriptions;
};

void usage(const char* progname)
{
	std::cerr << "usage: " << progname << " -d <input audio file> <output WAV file>" << std::endl
			  << "   or: " << progname << " -e <input WAV file> <output AAC file>" << std::endl;
}

int main(int argc, const char* argv[])
{
	if (argc < 4) {
		usage(argv[0]);
		return EXIT_FAILURE;
	}
	try {
		// Determine whether the sample decodes or encodes the audio.
		bool encode = false;
		if (!strcmp(argv[1], "-e")) {
			encode = true;
		} else if (strcmp(argv[1], "-d")) {
			usage(argv[0]);
			return EXIT_FAILURE;
		}

		// Open the input file and get its data format.
		auto inputFile = AudioFile::Open(argv[2]);
		AudioStreamBasicDescription inputDescription;
		inputFile.GetProperty(
			kAudioFilePropertyDataFormat,
			sizeof(inputDescription),
			&inputDescription);

		// If encoding, make sure the input data is PCM.
		if (encode && (inputDescription.mFormatID != kAudioFormatLinearPCM)) {
			std::cerr << "The input file data format is not PCM" << std::endl;
			return EXIT_FAILURE;
		}

		// Determine whether the input uses packet descriptions.
		const bool inputUsesPacketDescriptions =
			(inputDescription.mBytesPerPacket == 0 || inputDescription.mFramesPerPacket == 0);

		// Create the output file as PCM or AAC of the same sampling rate and number of channels as
		// the input.
		AudioStreamBasicDescription outputDescription{
			.mSampleRate = inputDescription.mSampleRate,
			.mChannelsPerFrame = inputDescription.mChannelsPerFrame,
		};
		AudioFileTypeID outputFileType;
		if (encode) {
			outputFileType = kAudioFileM4AType;
			outputDescription.mFormatID = kAudioFormatMPEG4AAC;
			outputDescription.mFormatFlags = kAudioFormatFlagsAreAllClear;
			outputDescription.mFramesPerPacket = 1024;
		} else {
			outputFileType = kAudioFileWAVEType;
			outputDescription.mFormatID = kAudioFormatLinearPCM;
			outputDescription.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
			outputDescription.mBytesPerPacket = 4 * inputDescription.mChannelsPerFrame;
			outputDescription.mFramesPerPacket = 1;
			outputDescription.mBytesPerFrame = 4 * inputDescription.mChannelsPerFrame;
			outputDescription.mBitsPerChannel = 32;
		}
		auto outputFile = AudioFile::Create(argv[3], outputFileType, outputDescription);

		// Create an AudioConverter for decoding or encoding the audio.
		AudioConverter audioConverter(inputDescription, outputDescription);

		// If decoding, provide the decoder with the magic cookie found in the file, if there is
		// one.
		if (!encode) {
			std::optional<size_t> magicCookieSize =
				inputFile.GetPropertySize(kAudioFilePropertyMagicCookieData);
			if (magicCookieSize.has_value()) {
				std::cout << "The magic cookie is "
						  << *magicCookieSize
				          << " bytes in size."
						  << std::endl;

				// Get the magic cookie from the input file.
				std::vector<uint8_t> magicCookie(*magicCookieSize);
				inputFile.GetProperty(
					kAudioFilePropertyMagicCookieData,
					magicCookie.size(),
					magicCookie.data());

				// Provide the magic cookie to the decoder, via the AudioConverter.
				audioConverter.SetProperty(kAudioConverterDecompressionMagicCookie,
					magicCookie.size(),
					magicCookie.data());
			} else {
				std::cout << "There is no magic cookie." << std::endl;
			}
		}

		// Determine the size of the largest input and output packets.
		UInt32 maxInputPacketSize, maxOutputPacketSize;
		if (encode) {
			// If encoding, the input packets are fixed size, and the converter indicates the
			// theoretical maximum output packet size.
			maxInputPacketSize = inputDescription.mBytesPerPacket;
			audioConverter.GetProperty(kAudioConverterPropertyMaximumOutputPacketSize,
									   sizeof(maxOutputPacketSize),
									   &maxOutputPacketSize);
		} else {
			// If decoding, scan the input file to find the maximum input packet size,
			// and the output packets are fixed size.
			inputFile.GetProperty(kAudioFilePropertyMaximumPacketSize,
								  sizeof(maxInputPacketSize),
								  &maxInputPacketSize);
			maxOutputPacketSize = outputDescription.mBytesPerPacket;
		}
		std::cout << "The maximum input packet size is " << maxInputPacketSize << " bytes."
				  << std::endl;
		std::cout << "The maximum output packet size is " << maxOutputPacketSize << " bytes."
				  << std::endl;

		// Set up a file-reading context to use for providing the AudioConverter
		// with input packets.
		InputContext inputContext(std::move(inputFile),
								  inputDescription,
								  maxInputPacketSize,
								  inputUsesPacketDescriptions);

		// Determine the number of output packets to attempt to produce
		// per loop, based on whether the sample is encoding.
		const UInt32 packetsPerLoop = encode ? 100 : 10000;

		// If encoding, the sample needs a buffer to accept the descriptions
		// of the output packets.
		std::vector<AudioStreamPacketDescription> packetDescriptions;
		if (encode) {
			packetDescriptions.resize((size_t)packetsPerLoop);
		}

		// Convert audio until the sample runs out of input.
		std::vector<uint8_t> packetBuffer((size_t)(packetsPerLoop * maxOutputPacketSize));
		for (;;) {
			// Try to handle more packets depending on whether the sample is encoding or decoding.
			UInt32 numPackets = packetsPerLoop;
			AudioBufferList abl{ 1, {
										outputDescription.mChannelsPerFrame, // mNumberChannels
										(UInt32)packetBuffer.size(),         // mDataByteSize
										packetBuffer.data()                  // mData
									} };
			audioConverter.FillComplexBuffer(InputContext::InputDataProc,
											 &inputContext,
											 numPackets,
											 abl,
											 encode ? packetDescriptions.data() : NULL);
            
			// If there are output packets, write them to the output file.
			if (numPackets > 0) {
				outputFile.WritePackets(abl.mBuffers[0].mDataByteSize,
										encode ? packetDescriptions.data() : NULL,
										numPackets,
										abl.mBuffers[0].mData);
			}
            
			// Stop if the sample decodes fewer packets than it requests.
			// This happens when the sample runs out of input.
			if (numPackets < packetsPerLoop) {
				break;
			}
		}
		std::cout << "Converted " << inputContext.NumPacketsRead() << " input packets to "
				  << outputFile.NextPacket() << " output packets." << std::endl;

		// If encoding, obtain the magic cookie from the encoder and write it to the file.
		// Note that the sample waits until the end of the encoding to do this, because the magic cookie
		// may update during the encoding process.
		if (encode) {
			// Get the magic cookie from the encoder, through the AudioConverter.
			const size_t magicCookieSize =
				audioConverter.GetPropertySize(kAudioConverterCompressionMagicCookie);
			std::cout << "The magic cookie is " << magicCookieSize << " bytes in size." << std::endl;
			std::vector<uint8_t> magicCookie(magicCookieSize);
			audioConverter.GetProperty(kAudioConverterCompressionMagicCookie,
									   magicCookie.size(),
									   magicCookie.data());

			// Write the magic cookie to the output file.
			outputFile.SetProperty(kAudioFilePropertyMagicCookieData,
								   magicCookie.size(),
								   magicCookie.data());
		}
        std::cout << "Finished " << (encode ? "encoding" : "decoding") << " the audio file "
                  << outputFile.GetFilePath() << std::endl;
	} catch (AudioToolboxError err) {
		std::cerr << "Encountered an error: " << err.what() << std::endl;
		return EXIT_FAILURE;
	}
	return EXIT_SUCCESS;
}
