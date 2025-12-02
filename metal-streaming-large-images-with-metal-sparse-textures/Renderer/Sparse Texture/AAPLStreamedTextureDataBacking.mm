/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the class that reads the texture data from a KTX file.
*/

#import "AAPLStreamedTextureDataBacking.h"
#import <sys/mman.h>
#import <sys/stat.h>

/// KTXTexHeader is used by AAPLStreamTextureDataBacking for loading KTX files.
typedef struct
{
    char     identifier[12];
    uint32_t endianness;
    uint32_t glType;
    uint32_t glTypeSize;
    uint32_t glFormat;
    uint32_t glInternalFormat;
    uint32_t glBaseInternalFormat;
    uint32_t pixelWidth;
    uint32_t pixelHeight;
    uint32_t pixelDepth;
    uint32_t numberOfArrayElements;
    uint32_t numberOfFaces;
    uint32_t numberOfMipmapLevels;
    uint32_t bytesOfKeyValueData;
} KTXTexHeader;

@implementation AAPLStreamedTextureDataBacking
{
    KTXTexHeader* _header;
}

/// Initialize the data backing using a KTX-formatted texture file data.
- (instancetype)initWithKTXPath:(NSURL*)path
{
    if (self = [super init])
    {
        _loaded = [self loadKTX: path];
    }
    return self;
}

/// Free the memory used by the class.
- (void)dealloc
{
    free(_mipmapOffsets);
    free(_mipmapLengths);
}

/// Return the texture region based on its mipmap level.
- (MTLRegion)calculateMipmapRegion:(NSUInteger)mipmapLevel
{
    return MTLRegionMake2D(0, 0, MAX(_width >> mipmapLevel, 1), MAX(_height >> mipmapLevel, 1));
}

/// Loads a KTX file and returns true if successful.
- (bool)loadKTX:(NSURL*)path
{
    if (![self loadKTXHeader:path])
    {
        return false;
    }

    _width              = _header->pixelWidth;
    _height             = _header->pixelHeight;
    _mipmapLevelCount   = _header->numberOfMipmapLevels;

    // Allocate the arrays storing the offsets and lengths of the mipmaps.
    _mipmapOffsets = (NSUInteger*)calloc(_mipmapLevelCount, sizeof(NSUInteger));
    _mipmapLengths = (NSUInteger*)calloc(_mipmapLevelCount, sizeof(NSUInteger));

    uint8_t* mappedData = (unsigned char*) _header;
    mappedData += sizeof(KTXTexHeader) + _header->bytesOfKeyValueData;
    
    uint8_t* textureDataStart = mappedData;
    uint32_t totalLength = 0u;
    uint32_t prevTotalOffset = sizeof(uint32_t);
    
    // Fill in the mipmap offset and length arrays.
    for (NSUInteger i = 0; i < _mipmapLevelCount; ++i)
    {
        // The first four bytes of each mipmap level hold the size of the mipmap level.
        uint32_t imageBytesLength = *(uint32_t*)mappedData;
        _mipmapOffsets[i] = prevTotalOffset;
        _mipmapLengths[i] = imageBytesLength;

        uint32_t currentOffset  = imageBytesLength + sizeof(uint32_t);
        mappedData              = mappedData + currentOffset;
        prevTotalOffset         = prevTotalOffset + currentOffset;
        totalLength             = totalLength + currentOffset;
    }
    
    // Holds the pointer to the mapped memory pages.
    _textureData = [NSData dataWithBytesNoCopy:textureDataStart length:totalLength];

    // Process the pixel format.
    return [self readPixelFormat];
}

/// Checks if the path exists and memory-maps the file if it has a valid KTX header.
- (bool)loadKTXHeader:(NSURL*)path
{
    NSError* error{};
    if ([path checkResourceIsReachableAndReturnError:&error] == NO)
    {
        NSLog(@"Couldn't find resource %@", path);
        return false;
    }

    _path = path;

    int fd = open(path.fileSystemRepresentation, O_RDONLY, 0);
    if (fd < 0)
    {
        NSLog(@"Couldn't open '%@'", path);
        return false;
    }

    // Check the size of the file to ensure you can load the header.
    struct stat fileInfo;
    if (fstat(fd, &fileInfo))
    {
        NSLog(@"Couldn't get file size for '%@'", path);
        close(fd);
        return false;
    }

    if (fileInfo.st_size < sizeof(KTXTexHeader))
    {
        NSLog(@"The file '%@' is too small", path);
        close(fd);
        return false;
    }
    
    // Map the entire texture data to memory pages.
    unsigned char* mappedData = (unsigned char *)mmap(NULL, fileInfo.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    // Make sure to close the file once the texture data is mapped.
    close(fd);

    if (mappedData == MAP_FAILED)
    {
        NSLog(@"Couldn't map '%@': %d", path, errno);
        return false;
    }

    // Identifier that checks if a texture file is a KTX file format or not.
    static const uint8_t KTXIdentifier[12] =
    {
       0xAB, 0x4B, 0x54, 0x58, 0x20, 0x31, 0x31, 0xBB, 0x0D, 0x0A, 0x1A, 0x0A
    };
    
    _header = (KTXTexHeader*)mappedData;

    // Check if the asset file identifier matches the KTX identifier and if the texture format is a 2D texture with at least one mipmap level.
    if ((memcmp(_header->identifier, KTXIdentifier, sizeof(KTXIdentifier)) != 0) ||
        _header->endianness != (0x04030201) ||
        _header->numberOfArrayElements > 0 ||
        _header->numberOfFaces > 1 ||
        _header->numberOfMipmapLevels == 0)
    {
        assert(0);
        return false;
    }
    
    return true;
}

- (bool)readPixelFormat
{
    _pixelFormat = MTLPixelFormatInvalid;
    switch (_header->glInternalFormat)
    {
        case 0x93B0: // GL_COMPRESSED_RGBA_ASTC_4x4_KHR (from KHR_texture_compression_astc_hdr extension)
            _pixelFormat = MTLPixelFormatASTC_4x4_sRGB;
            break;
        case 0x8058: // GL_RGBA8
            _pixelFormat = MTLPixelFormatRGBA8Unorm;
            break;
        case 0x8C43: // GL_SRGB8_ALPHA8
            _pixelFormat = MTLPixelFormatRGBA8Unorm_sRGB;
            break;
        default:
            break;
    }

    if (_pixelFormat == MTLPixelFormatInvalid)
    {
        assert(0);
        return false;
    }
    else
    {
        // The blockSize will be four because the included texture is an ASTC 4 x 4 texture.
        // Since the texture uses four channels per pixel, the value for bytes per block is 16.
        _blockSize = 4lu;
        _bytesPerBlock = 16lu;
    }
    
    return true;
}

@end
