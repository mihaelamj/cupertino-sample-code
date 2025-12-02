/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of a simple container that stores image data.
*/

#import "AAPLImage.h"
#include <simd/simd.h>

// A structure that fits the layout of a TGA header containing image metadata.
typedef struct __attribute__ ((packed)) TGAHeader
{
    uint8_t  IDSize;         // Size of ID information following the header.
    uint8_t  colorMapType;   // Determines whether the image is paletted.
    uint8_t  imageType;      // The type of image (0=none, 1=indexed, 2=rgb, 3=grey, +8=RLE packed).

    int16_t  colorMapStart;  // Offset to color map in palette.
    int16_t  colorMapLength; // Number of colors in palette.
    uint8_t  colorMapBpp;    // Number of bits per palette entry.

    uint16_t xOrigin;        // X-origin pixel of lower-left corner if the image is a tile of a larger image.
    uint16_t yOrigin;        // Y-origin pixel of lower-left corner if the image is a tile of a larger image.
    uint16_t width;          // Width in pixels.
    uint16_t height;         // Height in pixels.
    uint8_t  bitsPerPixel;   // Bits per pixel (8, 16, 24, 32).

    union __attribute__ ((packed))
    {
        struct __attribute__ ((packed))
        {
            uint8_t bitsPerAlpha : 4;
            uint8_t rightOrigin  : 1;
            uint8_t topOrigin    : 1;
            uint8_t interleave   : 2;
        };
        uint8_t imageDescriptor;
    };
} TGAHeader;

@implementation AAPLImage

-(nullable instancetype) initWithTGAFileAtLocation:(nonnull NSURL *)tgaLocation
{
    self = [super init];
    if (self)
    {
        NSString *fileExtension = tgaLocation.pathExtension;

        if (!([fileExtension caseInsensitiveCompare:@"TGA"] == NSOrderedSame))
        {
            NSLog(@"This image loader only loads TGA files.");
            return nil;
        }

        NSError *error;

        // Copy the entire file to this fileData variable.
        NSData *fileData = [[NSData alloc] initWithContentsOfURL:tgaLocation
                                                         options:0x0
                                                           error:&error];

        if (!fileData)
        {
            NSLog(@"Could not open the TGA file, error:%@", error.localizedDescription);
            return nil;
        }

        TGAHeader *tgaInfo = (TGAHeader *) fileData.bytes;

        if (tgaInfo->imageType != 2)
        {
            NSLog(@"This image loader supports only non-compressed BGR(A) TGA files.");
            return nil;
        }

        if (tgaInfo->colorMapType)
        {
            NSLog(@"This image loader doesn't support TGA files with a colormap.");
            return nil;
        }

        if (tgaInfo->xOrigin || tgaInfo->yOrigin)
        {
            NSLog(@"This image loader doesn't support TGA files with a non-zero origin.");
            return nil;
        }

        if (tgaInfo->interleave)
        {
            NSLog(@"This image loader doesn't support TGA files with interleaved data.");
            return nil;
        }

        NSUInteger srcBytesPerPixel;
        if (tgaInfo->bitsPerPixel == 32)
        {
            srcBytesPerPixel = 4;

            if (tgaInfo->bitsPerAlpha != 8)
            {
                NSLog(@"This image loader supports only 32-bit TGA files with 8 bits of alpha.");
                return nil;
            }

        }
        else if (tgaInfo->bitsPerPixel == 24)
        {
            srcBytesPerPixel = 3;

            if (tgaInfo->bitsPerAlpha != 0)
            {
                NSLog(@"This image loader supports only 24-bit TGA files with no alpha.");
                return nil;
            }
        }
        else
        {
            NSLog(@"This image loader supports only 24-bit and 32-bit TGA files.");
            return nil;
        }

        _width = tgaInfo->width;
        _height = tgaInfo->height;

        // The image data is stored as 32-bits-per-pixel BGRA data.
        NSUInteger dataSize = _width * _height * 4;

        // Metal doesn't support images with a 24-bit BGR format. Convert the image
        // pixels to a 32-bit BGRA format that Metal supports (MTLPixelFormatBGRA8Unorm).

        NSMutableData *mutableData = [[NSMutableData alloc] initWithLength:dataSize];

        // The TGA specification states that the image data is immediately after the header
        // and the ID. Set the pointer to `start + size of the header + size of the ID`.

        // Initialize a source pointer with the source image data that's in BGR form.
        uint8_t *srcImageData = ((uint8_t*)fileData.bytes +
                                 sizeof(TGAHeader) +
                                 tgaInfo->IDSize);

        // Initialize a destination pointer into which you store the converted BGRA image data.
        uint8_t *dstImageData = mutableData.mutableBytes;

        // For every row of the image, perform the following operations:
        for (NSUInteger y = 0; y < _height; y++)
        {
            // If bit 5 of the descriptor isn't set, flip vertically to transform the image
            // data to Metal's top-left texture origin.
            NSUInteger srcRow = (tgaInfo->topOrigin) ? y : _height - 1 - y;

            // For every column of the current row, perform the following operations.
            for (NSUInteger x = 0; x < _width; x++)
            {
                // If bit 4 of the descriptor is set, flip horizontally to transform the
                // image data to Metal's top-left texture origin.
                NSUInteger srcColumn = (tgaInfo->rightOrigin) ? _width - 1 - x : x;

                // Calculate the index for the first byte of the pixel in both the
                // source and destination images.
                NSUInteger srcPixelIndex = srcBytesPerPixel * (srcRow * _width + srcColumn);
                NSUInteger dstPixelIndex = 4 * (y * _width + x);

                // Copy BGR channels from the source to the destination.
                // Set the alpha channel of the destination pixel to 255.
                dstImageData[dstPixelIndex + 0] = srcImageData[srcPixelIndex + 0];
                dstImageData[dstPixelIndex + 1] = srcImageData[srcPixelIndex + 1];
                dstImageData[dstPixelIndex + 2] = srcImageData[srcPixelIndex + 2];

                if (tgaInfo->bitsPerPixel == 32)
                {
                    dstImageData[dstPixelIndex + 3] =  srcImageData[srcPixelIndex + 3];
                }
                else
                {
                    dstImageData[dstPixelIndex + 3] = 255;
                }
            }
        }
        _data = mutableData;
    }

    return self;
}

-(nullable instancetype)initWithBGRA8UnormData:(nonnull NSData *)data
                                         width:(NSUInteger)width
                                        height:(NSUInteger)height
{
    self = [super init];
    if (self)
    {
        if (data.length < 4 * width * height)
        {
            NSLog(@"The data provided isn't large enough to hold an image with %dx%d BGRA8Unorm pixels.",
                  (uint32_t)_width, (uint32_t)_height);
            return nil;
        }
        _data = data;
        _width = width;
        _height = height;
    }

    return self;
}

- (void)saveToTGAFileAtLocation:(nonnull NSURL *)location
{
    NSMutableData *data = [[NSMutableData alloc] initWithLength:sizeof(TGAHeader)];

    TGAHeader *tgaInfo = (TGAHeader*)data.mutableBytes;
    tgaInfo->IDSize         = 0;
    tgaInfo->colorMapType   = 0;
    tgaInfo->imageType      = 2;

    tgaInfo->colorMapStart  = 0;
    tgaInfo->colorMapLength = 0;
    tgaInfo->colorMapBpp    = 0;

    tgaInfo->xOrigin        = 0;
    tgaInfo->yOrigin        = 0;
    tgaInfo->width          = _width;
    tgaInfo->height         = _height;
    tgaInfo->bitsPerPixel   = 32;
    tgaInfo->bitsPerAlpha   = 8;
    tgaInfo->rightOrigin    = 0;
    tgaInfo->topOrigin      = 1;
    tgaInfo->interleave     = 0;

    [data appendData:_data];

    BOOL ok = [data writeToURL:location atomically:NO];

    if (ok == NO)
    {
        NSAssert(ok == YES, @"Error writing to @s\n", location);
    }
}

@end
