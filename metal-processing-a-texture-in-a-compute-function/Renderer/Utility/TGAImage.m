/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of an image data type that parses a TGA file.
*/

#import "TGAImage.h"


/// Defines the layout of a TGA file's image metadata.
typedef struct __attribute__ ((packed)) TGAHeader
{
    /// The size of the ID info that follows the header.
    uint8_t  IDSize;

    /// Inidcates whether the image uses a color palette.
    uint8_t  colorMapType;

    /// An enumeration that indicates the image's type.
    ///
    /// The values include:
    /// - `0`: No image data
    /// - `1`: Uncompressed color mapping
    /// - `2`: Uncompressed red, green, and blue (RBG)
    /// - `3`: Uncompressed grayscale
    /// - `>= 8`: Compressed format with run-length (RLE) encoding
    uint8_t  imageType;

    /// The offset to the color map in the palette.
    int16_t  colorMapStart;

    /// The mumber of colors in the palette.
    int16_t  colorMapLength;

    /// The number of bits per pixel in a palette entry.
    uint8_t  colorMapBpp;


    /// The horizontal component of the origin pixel.
    ///
    /// The origin pixel is the lower-left corner for files that represent
    /// a tile of a larger image.
    uint16_t originX;

    /// The vertical component of the origin pixel.
    ///
    /// The origin pixel is the lower-left corner for files that represent
    /// a tile of a larger image.
    uint16_t originY;

    /// The width of the image, in pixels.
    uint16_t width;

    /// The height of the image, in pixels.
    uint16_t height;

    /// The number of bits for each pixel.
    ///
    /// Possible values include:
    /// - `8`
    /// - `16`
    /// - `24`
    /// - `32`
    uint8_t  bitsPerPixel;

    union {
        struct
        {
            uint8_t bitsPerAlpha : 4;
            uint8_t rightOrigin  : 1;
            uint8_t topOrigin    : 1;
            uint8_t reserved     : 2;
        };
        uint8_t descriptor;
    };
} TGAHeader;


@implementation TGAImage

- (NSData *) getDataFromFileURL:(NSURL*)fileURL
{
    NSString * fileExtension = fileURL.pathExtension;

    if (NSOrderedSame != [fileExtension caseInsensitiveCompare:@"TGA"])
    {
        NSLog(@"The `TGAImage` type only loads TGA files.");
        return nil;
    }

    NSError * error;
    NSData *fileData = [[NSData alloc] initWithContentsOfURL:fileURL
                                                     options:0x0
                                                       error:&error];

    if (!fileData)
    {
        NSLog(@"Can't open TGA file at:%@\n due to:%@", fileURL,
              error.localizedDescription);
        return nil;
    }

    return fileData;
}

- (NSUInteger) getBytesPerPixelFromHeaderData:(TGAHeader *)headerData
{
    if (headerData->imageType != 2)
    {
        NSLog(@"The `TGAImage` type only supports non-compressed BGR(A) TGA files.");
        return 0;
    }

    if (headerData->colorMapType)
    {
        NSLog(@"The `TGAImage` type doesn't support TGA files with a colormap.");
        return 0;
    }

    if (headerData->originX || headerData->originY)
    {
        NSLog(@"The `TGAImage` type doesn't support TGA files with a non-zero origin.");
        return 0;
    }

    NSUInteger sourceBytesPerPixel = 0;
    if (headerData->bitsPerPixel == 32)
    {
        if (headerData->bitsPerAlpha == 8)
        {
            sourceBytesPerPixel = 4;
        } else
        {
            NSLog(@"The `TGAImage` type only supports 32-bit TGA files with 8 bits of alpha.");
        }

    }
    else if (headerData->bitsPerPixel == 24)
    {
        if (headerData->bitsPerAlpha == 0)
        {
            sourceBytesPerPixel = 3;
        } else
        {
            NSLog(@"The `TGAImage` type only supports 24-bit TGA files with no alpha.");
        }
    }
    else
    {
        NSLog(@"The `TGAImage` type only supports 24-bit and 32-bit TGA files.");
    }

    return sourceBytesPerPixel;
}


/// Creates an image with the contents of a TGA file.
/// - Parameter fileURL: A URL to a TGA file.
///  
/// Each instance stores 32 bits per pixel with:
/// - 4 color components: red, green blue, alpha (BGRA)
/// - 8 8 bits per color component
///
/// If the TGA file has 24-bit (BGR) format without the alpha channel,
/// the initializer converts it to the 32-bit BGRA format because the app works
/// with the `MTLPixelFormatBGRA8Unorm` format.
-(nullable instancetype) initWithTGAFileAtLocation:(nonnull NSURL *)fileURL
{
    self = [super init];
    if (nil == self)
    {
        return nil;
    }

    /// The data of the entire TGA file.
    NSData *fileData = [self getDataFromFileURL:fileURL];
    if (nil == fileData) {
        return nil;
    }

    TGAHeader *headerData = (TGAHeader *) fileData.bytes;
    const NSUInteger sourceBytesPerPixel = [self getBytesPerPixelFromHeaderData:headerData];

    if (0 == sourceBytesPerPixel) {
        return nil;
    }

    _width = headerData->width;
    _height = headerData->height;

    /// The total size of the image data.
    NSUInteger dataSize = _width * _height * 4;

    /// The image's underlying data storage.
    NSMutableData *mutableData = [[NSMutableData alloc] initWithLength:dataSize];

    /// A pointer to the beginning of the image data.
    ///
    /// The TGA specification states the image data starts immediately after the
    /// file's header and ID.
    uint8_t *sourceData = ((uint8_t*)fileData.bytes +
                           sizeof(TGAHeader) +
                           headerData->IDSize);

    /// A pointer to the underlying data that stores the image's final BGRA data.
    uint8_t *destinationData = mutableData.mutableBytes;

    // Process every row of the image.
    for (NSUInteger y = 0; y < _height; y++)
    {
        // Vertically flip the image if the 5th bit of the descriptor is clear
        // to match Metal's origin for textures, which is the top-left corner.
        NSUInteger row = (headerData->topOrigin) ? y : _height - 1 - y;

        // Process every column of the current row.
        for (NSUInteger x = 0; x < _width; x++)
        {
            // Horizontally flip the image if the 4th bit of the descriptor is set
            // to match Metal's origin for textures, which is the top-left corner.
            NSUInteger column = (headerData->rightOrigin) ? _width - 1 - x : x;

            /// The pixel index in the TGA file.
            NSUInteger sourceIndex = sourceBytesPerPixel * (row * _width + column);

            /// The equivalent pixel index in a Metal texture.
            NSUInteger destinationIndex = 4 * (y * _width + x);

            // Copy the blue channel.
            destinationData[destinationIndex + 0] = sourceData[sourceIndex + 0];

            // Copy the green channel.
            destinationData[destinationIndex + 1] = sourceData[sourceIndex + 1];

            // Copy the red channel.
            destinationData[destinationIndex + 2] = sourceData[sourceIndex + 2];

            if (headerData->bitsPerPixel == 32)
            {
                // Copy the alpha channel.
                destinationData[destinationIndex + 3] =  sourceData[sourceIndex + 3];
            }
            else
            {
                // Set the alpha channel to full opaque (no transparency).
                destinationData[destinationIndex + 3] = 255;
            }
        }
    }

    // Save the data to an immutable instance now that the conversion is done.
    _data = mutableData;

    return self;
}

@end
