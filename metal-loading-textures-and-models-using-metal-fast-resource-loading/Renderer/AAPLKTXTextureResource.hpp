/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header-only class to read meta information for KTX11 texture files.
*/

#pragma once

#include <string.h>
#include <vector>
#include <map>

#import <Metal/Metal.h>

/// KTXTextureHeader is for loading KTX files.
struct KTXTextureHeader
{
    uint8_t  identifier[12];
    uint32_t endianness{0};
    uint32_t glType{0};
    uint32_t glTypeSize{0};
    uint32_t glFormat{0};
    uint32_t glInternalFormat{0};
    uint32_t glBaseInternalFormat{0};
    uint32_t pixelWidth{0};
    uint32_t pixelHeight{0};
    uint32_t pixelDepth{0};
    uint32_t numberOfArrayElements{0};
    uint32_t numberOfFaces{0};
    uint32_t numberOfMipmapLevels{0};
    uint32_t bytesOfKeyValueData{0};
};

/// AAPLKTXTextureResource interprets the header information for a KTX11 file resource and determines the mipmap level sizes and offsets.
class AAPLKTXTextureResource
{
public:
    AAPLKTXTextureResource() {}
    
    inline void readHeaderFromPath(const char* path)
    {
        resourcePath = path;
        FILE* fin = fopen(path, "rb");
        if (!fin)
            return;
        fread((char*)&header, sizeof(KTXTextureHeader), 1, fin);
        
        uint8_t ktx1Identifier[12] = { 0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A };
        bool isKTX1 = strncmp((char*)ktx1Identifier, (char*)header.identifier, 12) == 0;        
        assert(isKTX1);
        
        size_t kvBytesRead = 0;
        while (kvBytesRead < header.bytesOfKeyValueData)
        {
            uint32_t kvCount;
            fread(&kvCount, 1, sizeof(uint32_t), fin);
            // Align to 4 bytes boundary.
            if (kvCount & 0x03) kvCount = (kvCount + 0x04) & ~0x03;
            std::vector<char> buffer(kvCount);
            fread(&buffer[0], kvCount, 1, fin);
            // Read the key-value pair that is separated by a '\0' character.
            std::string values[2];
            int vindex = 0;
            for (auto c : buffer)
            {
                if (!c) vindex++;
                if (vindex > 1) break;
                if (c) values[vindex].push_back(c);
            }
            keyValuePairs[values[0]] = values[1];
            kvBytesRead += 4 + kvCount;
        }
        assert(kvBytesRead == header.bytesOfKeyValueData);
        
        // Read mipmap sizes and offsets.
        if (isKTX1)
        {
            pixelFormat = determinePixelFormat();
            assert(pixelFormat != MTLPixelFormatInvalid);
            mipmapCount = 0;
            imageDataSizeInBytes = 0;
            
            // Record the offset and size of each mipmap level.
            for (int level = 0; level < header.numberOfMipmapLevels; level++)
            {
                // The first four bytes of each mipmap level holds the size of the level image data.
                uint32_t levelSizeInBytes;
                fread((char*)&levelSizeInBytes, sizeof(uint32_t), 1, fin);
                
                // But this size must also align to a four byte boundary.
                if (levelSizeInBytes & 0x03) levelSizeInBytes = (levelSizeInBytes + 0x04) & 0x03;
                
                // Update the total amount of the image and get the current file offset.
                imageDataSizeInBytes += levelSizeInBytes;
                size_t levelFileOffset = ftell(fin);
                
                // Record the offsets and sizes.
                mipmapFileOffsets.push_back(levelFileOffset);
                mipmapSizesInBytes.push_back(levelSizeInBytes);

                // Record data sizes based on ASTC 4x4 block compression or bytesPerPixel.
                MTLSize levelSize = MTLSizeMake(header.pixelWidth>>level, header.pixelHeight>>level, 1);
                size_t bytesPerRow = 0;
                if (compressed)
                    bytesPerRow = std::max<size_t>(levelSize.width / 4 * 16, 16);
                else
                    bytesPerRow = std::max<size_t>(levelSize.width * bytesPerPixel, 4);
                
                mipmapBytesPerRow.push_back(bytesPerRow);
                mipmapBytesPerImage.push_back(bytesPerRow * levelSize.height);
                mipmapSizes.push_back(levelSize);
                
                // Move forward the number of bytes for the image data to get to the next mipmap level.
                fseek(fin, levelSizeInBytes, SEEK_CUR);

                mipmapCount++;
            }
        }
        
        fclose(fin);
    }
    
    inline MTLPixelFormat determinePixelFormat()
    {
        pixelFormat = MTLPixelFormatInvalid;
        switch(header.glInternalFormat)
        {
            case 0x93B0: // GL_COMPRESSED_RGBA_ASTC_4x4_KHR (from KHR_texture_compression_astc_hdr extension)
                pixelFormat = MTLPixelFormatASTC_4x4_sRGB;
                bytesPerPixel = 1;
                compressed = true;
                break;
            case 0x8058: // GL_RGBA8
                pixelFormat = MTLPixelFormatRGBA8Unorm;
                bytesPerPixel = 4;
                compressed = false;
                break;
            case 0x8C43: // GL_SRGB8_ALPHA8
                pixelFormat = MTLPixelFormatRGBA8Unorm_sRGB;
                bytesPerPixel = 4;
                compressed = false;
                break;
            default:
                break;
        }
        return pixelFormat;
    }

    KTXTextureHeader header;
    
    size_t imageDataSizeInBytes{0};
    uint32_t bytesPerPixel;

    MTLPixelFormat pixelFormat{MTLPixelFormatInvalid};
    size_t mipmapCount{0};
    std::vector<size_t> mipmapFileOffsets;
    std::vector<size_t> mipmapSizesInBytes;
    std::vector<size_t> mipmapBytesPerRow;
    std::vector<size_t> mipmapBytesPerImage;
    std::vector<MTLSize> mipmapSizes;

    std::string resourcePath;
    bool compressed{false};
    std::map<std::string, std::string> keyValuePairs;
};
